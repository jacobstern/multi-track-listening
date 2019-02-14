#include <ctype.h>
#include <errno.h>
#include <lame/lame.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <memory.h>
#include <mpg123.h>

#define DEFAULT_BUFFER_SAMPLESS 65536

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

result_t open_file(const char *filename, const char *mode, FILE **file)
{
    *file = fopen(filename, mode);

    if (*file == NULL)
    {
        fprintf(stderr, "failed to open filename %s: %s", filename, strerror(errno));
        return RESULT_FAILURE;
    }

    return RESULT_SUCCESS;
}

result_t decode_mp3_mono(char *filename, buffer_list_t **buffer_list)
{
    int result = 0;
    mpg123_handle *handle = mpg123_new(NULL, &result);

    if (handle == NULL)
    {
        fprintf(stderr, "[mpg123] cannot create handle: %s\n", mpg123_plain_strerror(result));
        return RESULT_FAILURE;
    }

    mpg123_format_none(handle);
    result = mpg123_format(handle, 44100, MPG123_MONO, MPG123_ENC_SIGNED_16);

    if (result != MPG123_OK)
    {
        fprintf(stderr, "[mpg123] failed to set format: %s\n", mpg123_plain_strerror(result));
        return RESULT_FAILURE;
    }

    result = mpg123_open(handle, filename);

    if (result != MPG123_OK)
    {
        fprintf(stderr, "[mpg123] failed to open file: %s\n", mpg123_plain_strerror(result));
        return RESULT_FAILURE;
    }

    buffer_list_t *out_list = buffer_list_new();
    int done = 0;

    long rate;
    int channels, encoding;
    mpg123_getformat(handle, &rate, &channels, &encoding);

    size_t buffer_size = DEFAULT_BUFFER_SAMPLESS * sizeof(int16_t);

    while (!done)
    {
        buffer_t *buffer = buffer_new();
        buffer->bytes = (uint8_t *)malloc(buffer_size);
        size_t requested = buffer_size;
        size_t written = 0;
        result = mpg123_read(handle, buffer->bytes, requested, &written);

        if (result != MPG123_OK && result != MPG123_DONE)
        {
            fprintf(stderr, "[mpg123] failed to decode: %s\n", mpg123_plain_strerror(result));
            buffer_free(buffer);
            buffer_list_free(out_list);
            return RESULT_FAILURE;
        }

        buffer->size = written;
        buffer_list_append(out_list, buffer);

        done = result == MPG123_DONE;
    }

    mpg123_close(handle);

    *buffer_list = out_list;
    return RESULT_SUCCESS;
}

result_t encode_mp3(buffer_list_t *in_pcm_buffers, buffer_list_t **out_buffers)
{
    lame_t lame = lame_init();
    lame_set_in_samplerate(lame, 44100);
    lame_set_num_channels(lame, 1);

    buffer_list_t *buffers = NULL;

    int result = lame_init_params(lame);
    if (result < 0)
    {
        goto error;
    }

    buffers = buffer_list_new();
    buffer_list_t *current_buffer_cell = in_pcm_buffers;

    while (current_buffer_cell->head != NULL)
    {
        buffer_t *current_buffer = current_buffer_cell->head;
        int num_samples = current_buffer->size / 2;
        size_t buffer_size = 5 * num_samples / 4 + 7200;

        buffer_t *out_buffer = buffer_new();
        out_buffer->bytes = (uint8_t *)malloc(buffer_size);

        result = lame_encode_buffer(lame, (short int *)current_buffer->bytes, NULL, num_samples,
                                    out_buffer->bytes, buffer_size);
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

result_t write_buffers()
{
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

    result = parse_args(argc, argv, &outfile, &infile_l, &infile_r);

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
    result = decode_mp3_mono(infile_l, &pcm_buffers);

    if (is_failure(result))
    {
        return EXIT_FAILURE;
    }

    fprintf(stderr, "decoded %i buffers\n", buffer_list_length(pcm_buffers));

    buffer_list_t *mp3_buffers;
    result = encode_mp3(pcm_buffers, &mp3_buffers);

    if (is_failure(result))
    {
        return EXIT_FAILURE;
    }

    fprintf(stderr, "encoded %i buffers\n", buffer_list_length(mp3_buffers));

    buffer_list_free(pcm_buffers);
    buffer_list_free(mp3_buffers);

    return EXIT_SUCCESS;
}