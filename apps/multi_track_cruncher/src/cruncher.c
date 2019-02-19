#include <ctype.h>
#include <errno.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <math.h>
#include <memory.h>

#include <AL/al.h>
#include <AL/alc.h>
#include <AL/alext.h>
#include <lame/lame.h>
#include <libswresample/swresample.h>
#include <mpg123.h>

#define DEFAULT_BUFFER_SAMPLES 65536
#define STANDARD_SAMPLE_RATE 44100
#define FADEOUT_DURATION 0.8f

extern char *optarg;

extern int optind, opterr, optopt;

static LPALCLOOPBACKOPENDEVICESOFT alcLoopbackOpenDeviceSOFT;
static LPALCISRENDERFORMATSUPPORTEDSOFT alcIsRenderFormatSupportedSOFT;
static LPALCRENDERSAMPLESSOFT alcRenderSamplesSOFT;

typedef enum result
{
    RESULT_SUCCESS = 0,
    RESULT_FAILURE = 1
} result_t;

static inline int is_failure(result_t result)
{
    return result == RESULT_FAILURE;
}

static inline float clamp(float x, float min, float max)
{
    return fminf(fmaxf(x, min), max);
}

static inline int min(int a, int b)
{
    return a < b ? a : b;
}

typedef struct buffer
{
    uint8_t *bytes;
    size_t size;
} buffer_t;

buffer_t *buffer_new()
{
    buffer_t *buffer = (buffer_t *)malloc(sizeof(buffer_t));
    buffer->bytes = NULL;
    buffer->size = 0;
    return buffer;
}

void buffer_free(buffer_t *buffer)
{
    if (buffer->bytes != NULL)
    {
        free(buffer->bytes);
        buffer->bytes = NULL;
    }
    free(buffer);
}

typedef struct buffer_list
{
    buffer_t *head;
    struct buffer_list *tail;
} buffer_list_t;

buffer_list_t *buffer_list_new()
{
    buffer_list_t *list = (buffer_list_t *)malloc(sizeof(buffer_list_t));
    list->head = NULL;
    list->tail = NULL;
    return list;
}

void buffer_list_append(buffer_list_t *buffer_list, buffer_t *buffer)
{
    buffer_list_t *current = buffer_list;
    while (current->head != NULL)
    {
        current = current->tail;
    }
    current->tail = buffer_list_new();
    current->head = buffer;
}

int buffer_list_length(buffer_list_t *buffer_list)
{
    if (buffer_list->head == NULL)
    {
        return 0;
    }
    return 1 + buffer_list_length(buffer_list->tail);
}

void buffer_list_free(buffer_list_t *buffer_list)
{
    if (buffer_list->tail != NULL)
    {
        buffer_list_free(buffer_list->tail);
        buffer_list->tail = NULL;
    }
    if (buffer_list->head != NULL)
    {
        buffer_free(buffer_list->head);
        buffer_list->head = NULL;
    }
    free(buffer_list);
}

result_t parse_args(int argc, char **argv,
                    char **infile_l, char **infile_r, char **outfile)
{
    *outfile = NULL;

    int c;

    while ((c = getopt(argc, argv, "o:")) != -1)
    {
        switch (c)
        {
        case 'o':
            *outfile = optarg;
            break;
        case '?':
            return RESULT_FAILURE; // getopt provides an info message to stdout
        }
    }

    if (*outfile == NULL)
    {
        fprintf(stderr, "missing required argument -- 'o'\n");
        return RESULT_FAILURE;
    }

    int remaining = argc - optind;
    if (remaining != 2)
    {
        fprintf(stderr, "expected two positional arguments, got %d\n", remaining);
        return RESULT_FAILURE;
    }

    *infile_l = argv[optind];
    *infile_r = argv[optind + 1];

    return RESULT_SUCCESS;
}

result_t resample_for_processing(long sample_rate, int channels, buffer_list_t *in_buffers,
                                 buffer_list_t **out_buffers)
{
    int64_t in_channel_layout = AV_CH_LAYOUT_STEREO;
    if (channels == 1)
    {
        in_channel_layout = AV_CH_LAYOUT_MONO;
    }
    struct SwrContext *swr = swr_alloc_set_opts(NULL, AV_CH_LAYOUT_STEREO, AV_SAMPLE_FMT_FLT,
                                                STANDARD_SAMPLE_RATE, in_channel_layout, AV_SAMPLE_FMT_S16,
                                                sample_rate, 0, NULL);
    if (swr == NULL)
    {
        fprintf(stderr, "[swresample] failed to create context\n");
    }
    int result = swr_init(swr);
    if (result < 0)
    {
        char errbuf[64];
        av_strerror(result, errbuf, 64);
        swr_free(&swr);
        fprintf(stderr, "[swresample] error initializing context: %s\n", errbuf);
    }

    buffer_list_t *buffers = buffer_list_new();
    buffer_list_t *cell = in_buffers;
    while (cell->head != NULL)
    {
        buffer_t *in_buffer = cell->head;
        int src_num_samples = in_buffer->size / sizeof(int16_t) / channels;
        int max_dst_num_samples = av_rescale_rnd(
            swr_get_delay(swr, sample_rate) + src_num_samples,
            STANDARD_SAMPLE_RATE, sample_rate, AV_ROUND_UP);
        size_t dst_size = max_dst_num_samples * sizeof(float) * 2;

        buffer_t *out_buffer = buffer_new();
        out_buffer->bytes = (uint8_t *)malloc(dst_size);

        int samples = swr_convert(swr, &out_buffer->bytes,
                                  max_dst_num_samples,
                                  (const uint8_t **)&in_buffer->bytes, src_num_samples);
        if (samples < 0)
        {
            char errbuf[64];
            av_strerror(result, errbuf, 64);
            buffer_free(out_buffer);
            buffer_list_free(buffers);
            swr_free(&swr);
            fprintf(stderr, "[swresample] conversion error: %s\n", errbuf);
        }

        out_buffer->size = samples * sizeof(float) * 2;
        buffer_list_append(buffers, out_buffer);
        cell = cell->tail;
    }

    *out_buffers = buffers;

    swr_free(&swr);

    return RESULT_SUCCESS;
}

result_t format_for_encoding(buffer_list_t *float_pcm_buffers, buffer_list_t **out_int_pcm_buffers)
{
    buffer_list_t *int_pcm_buffers = buffer_list_new();

    buffer_list_t *cell = float_pcm_buffers;
    while (cell->head != NULL)
    {
        buffer_t *buffer = cell->head;
        int num_samples = buffer->size / sizeof(float);
        buffer_t *int_pcm_buffer = buffer_new();
        size_t dst_size = num_samples * sizeof(int16_t);
        int_pcm_buffer->bytes = (uint8_t *)malloc(dst_size);
        int_pcm_buffer->size = dst_size;
        float *float_samples = (float *)buffer->bytes;
        int16_t *int_samples = (int16_t *)int_pcm_buffer->bytes;

        for (int i = 0; i < num_samples; i++)
        {
            float sample = float_samples[i];
            int16_t quantized = (int16_t)clamp(floorf(sample * INT16_MAX), (float)INT16_MIN, (float)INT16_MAX);
            int_samples[i] = quantized;
        }

        buffer_list_append(int_pcm_buffers, int_pcm_buffer);
        cell = cell->tail;
    }

    *out_int_pcm_buffers = int_pcm_buffers;

    return RESULT_SUCCESS;
}

result_t decode_mp3(char *filename, long *out_sample_rate, int *out_channels,
                    buffer_list_t **buffer_list)
{
    int result = 0;
    mpg123_handle *handle = mpg123_new(NULL, &result);

    if (handle == NULL)
    {
        fprintf(stderr, "[mpg123] cannot create handle: %s\n", mpg123_plain_strerror(result));
        return RESULT_FAILURE;
    }

    result = mpg123_open(handle, filename);

    if (result != MPG123_OK)
    {
        fprintf(stderr, "[mpg123] failed to open file: %s\n", mpg123_strerror(handle));
        return RESULT_FAILURE;
    }

    buffer_list_t *out_list = buffer_list_new();
    int done = 0;

    long sample_rate = 0;
    int channels = 0, encoding = 0;
    mpg123_getformat(handle, &sample_rate, &channels, &encoding);

    if (encoding != MPG123_ENC_SIGNED_16)
    {
        fprintf(stderr, "[mpg123] unexpected encoding %i\n", encoding);
        mpg123_close(handle);
        return RESULT_FAILURE;
    }

    size_t buffer_size = DEFAULT_BUFFER_SAMPLES * channels * sizeof(int16_t);

    while (!done)
    {
        buffer_t *buffer = buffer_new();
        buffer->bytes = (uint8_t *)malloc(buffer_size);
        size_t requested = buffer_size;
        size_t written = 0;
        result = mpg123_read(handle, buffer->bytes, requested, &written);

        if (result != MPG123_OK && result != MPG123_DONE)
        {
            fprintf(stderr, "[mpg123] failed to decode: %s\n", mpg123_strerror(handle));
            buffer_free(buffer);
            buffer_list_free(out_list);
            mpg123_close(handle);
            return RESULT_FAILURE;
        }

        buffer->size = written;
        buffer_list_append(out_list, buffer);

        done = result == MPG123_DONE;
    }

    mpg123_close(handle);

    *out_sample_rate = sample_rate;
    *out_channels = channels;
    *buffer_list = out_list;

    return RESULT_SUCCESS;
}

result_t encode_mp3(buffer_list_t *in_pcm_buffers, buffer_list_t **out_buffers)
{
    lame_t lame = lame_init();
    lame_set_in_samplerate(lame, 44100);
    lame_set_num_channels(lame, 2);

    buffer_list_t *buffers = NULL;

    int result = lame_init_params(lame);
    if (result < 0)
    {
        fprintf(stderr, "[lame] error with initialization");
        goto error;
    }

    buffers = buffer_list_new();
    buffer_list_t *current_buffer_cell = in_pcm_buffers;

    while (current_buffer_cell->head != NULL)
    {
        buffer_t *current_buffer = current_buffer_cell->head;
        int num_samples = current_buffer->size / 4;
        size_t buffer_size = 5 * num_samples / 4 + 7200;

        buffer_t *out_buffer = buffer_new();
        out_buffer->bytes = (uint8_t *)malloc(buffer_size);

        result = lame_encode_buffer_interleaved(lame, (short int *)current_buffer->bytes,
                                                num_samples, out_buffer->bytes, buffer_size);
        if (result < 0)
        {
            char reason[64] = "unknown";
            switch (result)
            {
            case -1:
                sprintf(reason, "mp3 buffer too small");
                break;
            case -2:
                sprintf(reason, "malloc() problem");
                break;
            case -3:
                sprintf(reason, "lame_init_params() not called");
                break;
            case -4:
                sprintf(reason, "psycho acoustic problems");
                break;
            }

            fprintf(stderr, "[lame] encoding error: %s", reason);
            buffer_free(out_buffer);
            goto error;
        }

        out_buffer->size = result;
        buffer_list_append(buffers, out_buffer);

        current_buffer_cell = current_buffer_cell->tail;
    }

    buffer_t *remaining = buffer_new();
    remaining->bytes = (uint8_t *)malloc(7200);
    remaining->size = lame_encode_flush(lame, remaining->bytes, 7200);
    buffer_list_append(buffers, remaining);

    lame_close(lame);

    *out_buffers = buffers;

    return RESULT_SUCCESS;

error:
    lame_close(lame);

    if (buffers != NULL)
    {
        buffer_list_free(buffers);
    }

    return RESULT_FAILURE;
}

result_t write_buffers(const char *filename, buffer_list_t *in_buffers)
{
    FILE *file = fopen(filename, "wb");

    if (file == NULL)
    {
        fprintf(stderr, "failed to open filename %s for writing: %s", filename, strerror(errno));
        return RESULT_FAILURE;
    }

    buffer_list_t *cell = in_buffers;
    while (cell->head != NULL)
    {
        buffer_t *buffer = cell->head;
        fwrite((const void *)buffer->bytes, sizeof(uint8_t), buffer->size, file);
        cell = cell->tail;
    }

    fclose(file);
    return RESULT_SUCCESS;
}

result_t al_buffer_data_from_list(buffer_list_t *buffers, ALsizei count, ALuint *out_al_buffers)
{
    buffer_list_t *cell = buffers;

    for (int i = 0; i < count; i++)
    {
        buffer_t *buffer = cell->head;
        alBufferData(out_al_buffers[i], AL_FORMAT_STEREO_FLOAT32, buffer->bytes, buffer->size,
                     STANDARD_SAMPLE_RATE);

        ALenum err = alGetError();

        if (err != AL_NO_ERROR)
        {
            fprintf(stderr, "[openal-soft] error filling buffer: %s\n", alGetString(err));
            alDeleteBuffers(count, out_al_buffers);
            return RESULT_FAILURE;
        }

        cell = cell->tail;
    }

    return RESULT_SUCCESS;
}

result_t mashup_tracks(buffer_list_t *buffers_l, buffer_list_t *buffers_r, int output_length_seconds,
                       buffer_list_t **out_mashup_buffers)
{
    // resources declared upfront for error label
    ALCdevice *device = NULL;

    ALCcontext *context = NULL;
    buffer_list_t *mashup_buffers = NULL;
    ALuint *al_buffers = NULL;
    ALsizei num_generated_buffers = 0;
    ALuint sources[2];
    ALuint num_generated_sources = 0;
    ALenum err = AL_NO_ERROR;

    device = alcLoopbackOpenDeviceSOFT(NULL);

    if (device == NULL)
    {
        fprintf(stderr, "[openal-soft] failed to create loopback device\n");
        goto error;
    }

    if (!alcIsExtensionPresent(device, "ALC_SOFT_HRTF"))
    {
        alcCloseDevice(device);
        fprintf(stderr, "[openal-soft] ALC_SOFT_HRTF not supported\n");
        goto error;
    }

    if (!alcIsRenderFormatSupportedSOFT(device, STANDARD_SAMPLE_RATE, ALC_STEREO_SOFT,
                                        ALC_FLOAT_SOFT))
    {
        fprintf(stderr, "[openal-soft] render format not supported\n");
        goto error;
    }

    ALCint attrs[] = {
        ALC_FREQUENCY, STANDARD_SAMPLE_RATE,
        ALC_FORMAT_CHANNELS_SOFT, ALC_STEREO_SOFT,
        ALC_FORMAT_TYPE_SOFT, ALC_FLOAT_SOFT,
        ALC_HRTF_SOFT, ALC_TRUE, /* request HRTF */
        0};
    context = alcCreateContext(device, attrs);

    if (context == NULL)
    {
        err = alcGetError(device);
        fprintf(stderr, "[openal-soft] failed to create context: %s\n", alcGetString(device, err));
        goto error;
    }

    ALboolean success = alcMakeContextCurrent(context);

    if (success == AL_FALSE)
    {
        err = alcGetError(device);
        fprintf(stderr, "[openal-soft] error making context current: %s\n", alcGetString(device, err));
        goto error;
    }

    if (!alIsExtensionPresent("AL_EXT_STEREO_ANGLES"))
    {
        fprintf(stderr, "[openal-soft] AL_EXT_STEREO_ANGLES not supported\n");
        goto error;
    }

    if (!alIsExtensionPresent("AL_EXT_float32"))
    {
        fprintf(stderr, "[openal-soft] AL_EXT_float32 not supported\n");
        goto error;
    }

    alDistanceModel(AL_LINEAR_DISTANCE);

    int num_buffers_l = buffer_list_length(buffers_l);
    int num_buffers_r = buffer_list_length(buffers_r);
    al_buffers = (ALuint *)malloc((num_buffers_l + num_buffers_r) * sizeof(ALuint));

    alGenBuffers(num_buffers_l + num_buffers_r, al_buffers);
    err = alGetError();

    if (err != AL_NO_ERROR)
    {
        fprintf(stderr, "[openal-soft] error creating buffers: %s\n", alGetString(err));
        goto error;
    }

    num_generated_buffers = num_buffers_l + num_buffers_r;
    ALuint *al_buffers_l = &al_buffers[0];
    ALuint *al_buffers_r = &al_buffers[num_buffers_l];

    result_t result = al_buffer_data_from_list(buffers_l, num_buffers_l, al_buffers_l);
    if (is_failure(result))
    {
        goto error;
    }

    result = al_buffer_data_from_list(buffers_r, num_buffers_r, al_buffers_r);
    if (is_failure(result))
    {
        goto error;
    }

    alGenSources(2, sources);

    err = alGetError();
    if (err != AL_NO_ERROR)
    {
        fprintf(stderr, "[openal-soft] error creating sources: %s\n", alGetString(err));
        goto error;
    }
    else
    {
        num_generated_sources = 2;
    }

    ALuint source_l = sources[0];
    ALuint source_r = sources[1];

    for (int i = 0; i < 2; i++)
    {
        alSourcef(sources[i], AL_REFERENCE_DISTANCE, 1.0f);
    }

    err = alGetError();
    if (err != AL_NO_ERROR)
    {
        fprintf(stderr, "[openal-soft] error configuring sources: %s\n", alGetString(err));
        goto error;
    }

    alSourceQueueBuffers(source_l, num_buffers_l, al_buffers_l);
    alSourceQueueBuffers(source_r, num_buffers_r, al_buffers_r);

    err = alGetError();
    if (err != AL_NO_ERROR)
    {
        fprintf(stderr, "[openal-soft] error queuing buffers: %s\n", alGetString(err));
        goto error;
    }

    alSourcePlayv(2, sources);

    if (err != AL_NO_ERROR)
    {
        fprintf(stderr, "[openal-soft] error playing sources: %s\n", alGetString(err));
        goto error;
    }

    ALsizei total_samples = STANDARD_SAMPLE_RATE * output_length_seconds;
    ALsizei processed_samples = 0;

    mashup_buffers = buffer_list_new();
    while (processed_samples < total_samples)
    {
        ALsizei initial_processed = processed_samples;
        float initial_time_seconds = (float)initial_processed / STANDARD_SAMPLE_RATE;
        int samples_per_batch = STANDARD_SAMPLE_RATE / 60; // update parameters and render at a granularity of 60 hz
        size_t batch_size = samples_per_batch * sizeof(float) * 2;
        ALsizei max_samples = min(total_samples - processed_samples + samples_per_batch, STANDARD_SAMPLE_RATE);
        size_t dst_size = max_samples * sizeof(float) * 2;

        buffer_t *mashup_buffer = buffer_new();
        mashup_buffer->bytes = (uint8_t *)malloc(dst_size);

        for (int batch = 0; batch < 60; batch++)
        {
            // TODO: try rendering tracks in mono
            float current_time_seconds = initial_time_seconds + batch / 60.0f;
            float angle = fmodf(current_time_seconds * M_PI * 2.0f / 10.0f, M_PI * 2.0f);
            float opposite_angle = M_PI * 2.0f - angle;

            ALfloat angles_l[2] = {(ALfloat)(M_PI / 6.0 - opposite_angle), (ALfloat)(-M_PI / 6.0 - opposite_angle)};
            alSourcefv(source_l, AL_STEREO_ANGLES, angles_l);

            ALfloat angles_r[2] = {(ALfloat)(M_PI / 6.0 - angle), (ALfloat)(-M_PI / 6.0 - angle)};
            alSourcefv(source_r, AL_STEREO_ANGLES, angles_r);

            if (output_length_seconds - current_time_seconds < FADEOUT_DURATION)
            {
                float fadeout_gain = ((float)output_length_seconds - current_time_seconds) / FADEOUT_DURATION;
                for (int i = 0; i < 2; i++)
                {
                    alSourcef(sources[i], AL_GAIN, fadeout_gain);
                }
            }

            uint8_t *samples_dst = &mashup_buffer->bytes[batch * batch_size];
            alcRenderSamplesSOFT(device, samples_dst, samples_per_batch);
            processed_samples += samples_per_batch;

            if (processed_samples >= total_samples)
            {
                break;
            }
        }

        mashup_buffer->size = (processed_samples - initial_processed) * sizeof(float) * 2;
        buffer_list_append(mashup_buffers, mashup_buffer);
    }

    alSourceStop(source_l);
    alSourcei(source_l, AL_BUFFER, 0);

    alSourceStop(source_r);
    alSourcei(source_r, AL_BUFFER, 0);

    alDeleteBuffers(num_generated_buffers, al_buffers);
    free(al_buffers);

    alDeleteSources(num_generated_sources, sources);

    alcMakeContextCurrent(NULL);
    alcDestroyContext(context);
    alcCloseDevice(device);

    *out_mashup_buffers = mashup_buffers;

    return RESULT_SUCCESS;

error:
    if (device != NULL)
    {
        alcCloseDevice(device);
    }
    if (context != NULL)
    {
        alcMakeContextCurrent(NULL);
        alcDestroyContext(context);
    }
    if (mashup_buffers != NULL)

    {

        buffer_list_free(mashup_buffers);
        mashup_buffers = NULL;
    }
    if (al_buffers != NULL)
    {
        if (num_generated_buffers > 0)
        {
            alDeleteBuffers(num_generated_buffers, al_buffers);
        }
        free(al_buffers);
        al_buffers = NULL;
    }
    if (num_generated_sources > 0)
    {
        alDeleteSources(num_generated_sources, sources);
    }
    return RESULT_FAILURE;
}

result_t initialize_libraries()
{
    mpg123_init();

    if (!alcIsExtensionPresent(NULL, "ALC_SOFT_loopback"))
    {
        fprintf(stderr, "[openal-soft] ALC_SOFT_loopback not supported\n");
        return RESULT_FAILURE;
    }

#define LOAD_PROC(x) ((x) = alcGetProcAddress(NULL, #x))
    LOAD_PROC(alcLoopbackOpenDeviceSOFT);
    LOAD_PROC(alcIsRenderFormatSupportedSOFT);
    LOAD_PROC(alcRenderSamplesSOFT);
#undef LOAD_PROC

    return RESULT_SUCCESS;
}

result_t float_pcm_from_mp3(char *filename, buffer_list_t **out_float_pcm_buffers)
{
    buffer_list_t *pcm_buffers = NULL;
    buffer_list_t *resampled_buffers = NULL;
    long sample_rate = 0;
    int channels = 0;
    result_t result = RESULT_SUCCESS;

    result = decode_mp3(filename, &sample_rate, &channels, &pcm_buffers);

    if (is_failure(result))
    {
        return RESULT_FAILURE;
    }

    fprintf(stderr, "decoded %i buffers\n", buffer_list_length(pcm_buffers));
    fprintf(stderr, "decoding sample rate: %li\n", sample_rate);

    result = resample_for_processing(sample_rate, channels, pcm_buffers, &resampled_buffers);

    buffer_list_free(pcm_buffers);
    pcm_buffers = NULL;

    if (is_failure(result))
    {
        return RESULT_FAILURE;
    }

    *out_float_pcm_buffers = resampled_buffers;
    return RESULT_SUCCESS;
}

int main(int argc, char **argv)
{
    char *outfile, *infile_l, *infile_r;
    result_t result;

    result = parse_args(argc, argv, &infile_l, &infile_r, &outfile);

    if (is_failure(result))
    {
        return EXIT_FAILURE;
    }

    result = initialize_libraries();

    if (is_failure(result))
    {
        return EXIT_FAILURE;
    }

    buffer_list_t *mashup_input_l;
    result = float_pcm_from_mp3(infile_l, &mashup_input_l);

    if (is_failure(result))
    {
        return EXIT_FAILURE;
    }

    buffer_list_t *mashup_input_r;
    result = float_pcm_from_mp3(infile_r, &mashup_input_r);

    if (is_failure(result))
    {
        return EXIT_FAILURE;
    }

    buffer_list_t *mashup_buffers;
    result = mashup_tracks(mashup_input_l, mashup_input_r, 90, &mashup_buffers);

    if (is_failure(result))
    {
        return EXIT_FAILURE;
    }

    buffer_list_free(mashup_input_l);
    mashup_input_l = NULL;
    buffer_list_free(mashup_input_r);
    mashup_input_r = NULL;

    buffer_list_t *int_buffers;
    result = format_for_encoding(mashup_buffers, &int_buffers);

    if (is_failure(result))
    {
        return EXIT_FAILURE;
    }

    buffer_list_free(mashup_buffers);
    mashup_buffers = NULL;

    buffer_list_t *mp3_buffers;
    result = encode_mp3(int_buffers, &mp3_buffers);

    if (is_failure(result))
    {
        return EXIT_FAILURE;
    }

    buffer_list_free(int_buffers);
    int_buffers = NULL;

    fprintf(stderr, "encoded %i buffers\n", buffer_list_length(mp3_buffers));

    write_buffers(outfile, mp3_buffers);

    buffer_list_free(mp3_buffers);
    mp3_buffers = NULL;

    return EXIT_SUCCESS;
}
