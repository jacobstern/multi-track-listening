#include <ctype.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>

extern char *optarg;

extern int optind, opterr, optopt;

int main(int argc, char **argv)
{
    char *outfile = NULL;
    int c;

    while ((c = getopt(argc, argv, "o:")) != -1)
    {
        switch (c)
        {
        case 'o':
            outfile = optarg;
            break;
        case '?':
            if (optopt == 'o')
                fprintf(stderr, "Option -%c requires an argument.\n", optopt);
            else if (isprint(optopt))
                fprintf(stderr, "Unknown option `-%c'.\n", optopt);
            else
                fprintf(stderr,
                        "Unknown option character `\\x%x'.\n",
                        optopt);
            return 1;
        }
    }

    if (outfile == NULL)
    {
        fprintf(stderr, "Missing required argument -o.\n");
    }

    int remaining = argc - optind;
    if (remaining != 2)
    {
        fprintf(stderr, "Expected two positional arguments, got %d.\n", remaining);
        return 1;
    }

    char *infile_l = argv[optind];
    char *infile_r = argv[optind + 1];

    return 0;
}