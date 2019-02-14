#include <ctype.h>
#include <errno.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <memory.h>

#include <lame/lame.h>
#include <libswresample/swresample.h>
#include <mpg123.h>

#define DEFAULT_BUFFER_SAMPLES 65536
#define SAMPLE_RATE 44100

extern char *optarg;

extern int optind, opterr, optopt;

typedef enum result
{
    RESULT_SUCCESS = 0,
    RESULT_FAILURE = 1
} result_t;

int is_failure(result_t result)
{
    return result == RESULT_FAILURE;
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
    struct SwrContext *swr = swr_alloc_set_opts(NULL, AV_CH_LAYOUT_STEREO, AV_SAMPLE_FMT_S16,
                                                SAMPLE_RATE, in_channel_layout, AV_SAMPLE_FMT_S16,
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
            SAMPLE_RATE, sample_rate, AV_ROUND_UP);
        size_t dst_size = max_dst_num_samples * sizeof(int16_t) * 2;

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

        out_buffer->size = samples * sizeof(int16_t) * 2;
        buffer_list_append(buffers, out_buffer);
        cell = cell->tail;
    }

    *out_buffers = buffers;

    swr_free(&swr);

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

    // const long *available_rates;
    // size_t number_rates = 0;
    // mpg123_rates(&available_rates, &number_rates);

    // for (int i = 0; i < number_rates; i++)
    // {
    //     fprintf(stderr, "supports rate %li\n", available_rates[i]);
    // }

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

    size_t buffer_size = DEFAULT_BUFFER_SAMPLES * 2 * sizeof(int16_t);

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

result_t initialize_libraries()
{
    mpg123_init();

    return RESULT_SUCCESS;
}

int main(int argc, char **argv)
{
    char *outfile, *infile_l, *infile_r;
    int result;

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

    buffer_list_t *pcm_buffers;
    long sample_rate;
    int channels;

    result = decode_mp3(infile_l, &sample_rate, &channels, &pcm_buffers);

    if (is_failure(result))
    {
        return EXIT_FAILURE;
    }

    fprintf(stderr, "decoded %i buffers\n", buffer_list_length(pcm_buffers));
    fprintf(stderr, "decoding sample rate: %li\n", sample_rate);

    buffer_list_t *resampled_buffers;
    result = resample_for_processing(sample_rate, channels, pcm_buffers, &resampled_buffers);

    if (is_failure(result))
    {
        return EXIT_FAILURE;
    }

    buffer_list_t *mp3_buffers;
    result = encode_mp3(resampled_buffers, &mp3_buffers);

    if (is_failure(result))
    {
        return EXIT_FAILURE;
    }

    fprintf(stderr, "encoded %i buffers\n", buffer_list_length(mp3_buffers));

    write_buffers(outfile, mp3_buffers);

    buffer_list_free(pcm_buffers);
    buffer_list_free(mp3_buffers);

    return EXIT_SUCCESS;
}