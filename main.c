#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <math.h>
#include <stdlib.h>
#include <stdbool.h>
#include <ctype.h>

typedef int8_t CHAR;
typedef uint8_t BYTE;
typedef int16_t SHORT;
typedef uint16_t WORD;
typedef int32_t LONG;
typedef uint32_t DWORD;

struct BITMAPINFOHEADER {
    DWORD biSize;
    LONG  biWidth;
    LONG  biHeight;
    WORD  biPlanes;
    WORD  biBitCount;
    DWORD biCompression;
    DWORD biSizeImage;
    LONG  biXPelsPerMeter;
    LONG  biYPelsPerMeter;
    DWORD biClrUsed;
    DWORD biClrImportant;
};

struct RGBQUAD {
    BYTE rgbBlue;
    BYTE rgbGreen;
    BYTE rgbRed;
    BYTE rgbReserved;
};

struct VERTEXDATA {
    LONG posX;
    LONG posY;
    BYTE colR;
    BYTE colG;
    BYTE colB;
};

void set_file_header(BYTE (*header)[14], DWORD file_size, DWORD headers_length)
{
    if (header != NULL) {
        (*header)[0] = 'B';
        (*header)[1] = 'M';
        memcpy(&(*header)[2], &file_size, 4);
        memset(&(*header)[6], 0, 4);
        memcpy(&(*header)[10], &headers_length, 4);
    }
}

void set_info_header(struct BITMAPINFOHEADER *header, LONG width, LONG height)
{
    if (header != NULL) {
        header->biSize = sizeof(*header);
        header->biWidth = width;
        header->biHeight = height;
        header->biPlanes = 1;
        header->biBitCount = 24;
        header->biCompression = 0;
        header->biSizeImage = abs(width * height) * 3;
        header->biXPelsPerMeter = 0;
        header->biYPelsPerMeter = 0;
        header->biClrUsed = 0;
        header->biClrImportant = 0;
    }
}

void set_vertex(struct VERTEXDATA *vertex, LONG pos_x, LONG pos_y, BYTE col_r, BYTE col_g, BYTE col_b)
{
    if (vertex != NULL) {
        vertex->posX = pos_x;
        vertex->posY = pos_y;
        vertex->colR = col_r;
        vertex->colG = col_g;
        vertex->colB = col_b;
    }
}

void clear_bitmap(BYTE *image_data, struct BITMAPINFOHEADER *info_header, BYTE red, BYTE green, BYTE blue)
{
    if (image_data != NULL && info_header != NULL) {
        size_t stride = (abs(info_header->biWidth) * 3 + 3) & 0xfffffffc;
        for (LONG i = 0; i < abs(info_header->biWidth); i++) {
            (image_data + i * 3)[0] = blue;
            (image_data + i * 3)[1] = green;
            (image_data + i * 3)[2] = red;
        }
        for (LONG i = 1; i < abs(info_header->biHeight); i++) {
            memcpy(image_data + i * stride, image_data, stride);
        }
    }
}

void swap_vertices(struct VERTEXDATA *a, struct VERTEXDATA *b)
{
    if (a != NULL && b != NULL) {
        struct VERTEXDATA tmp;
        memcpy(&tmp, a, sizeof(struct VERTEXDATA));
        memcpy(a, b, sizeof(struct VERTEXDATA));
        memcpy(b, &tmp, sizeof(struct VERTEXDATA));
    }
}

void sort_vertices(struct VERTEXDATA (*vertex_data)[3])
{
    if (vertex_data != NULL) {
        if ((*vertex_data)[1].posY < (*vertex_data)[0].posY) {
            swap_vertices(&(*vertex_data)[0], &(*vertex_data)[1]);
        }
        if ((*vertex_data)[2].posY < (*vertex_data)[1].posY) {
            swap_vertices(&(*vertex_data)[1], &(*vertex_data)[2]);
        }
        if ((*vertex_data)[1].posY < (*vertex_data)[0].posY) {
            swap_vertices(&(*vertex_data)[0], &(*vertex_data)[1]);
        }
    }
}

void draw_triangle(BYTE *image_data, struct BITMAPINFOHEADER *info_header, struct VERTEXDATA (*vertices)[3])
{
    if (image_data != NULL && info_header != NULL && vertices != NULL) {
        struct VERTEXSTEP {
            float x, r, g, b;
        } step[3] = {{}, {}, {}};
        if ((*vertices)[0].posY != (*vertices)[1].posY) {
            float difference = (*vertices)[0].posY - (*vertices)[1].posY;
            step[0].x = ((*vertices)[0].posX - (*vertices)[1].posX) / difference;
            step[0].r = ((*vertices)[0].colR - (*vertices)[1].colR) / difference;
            step[0].g = ((*vertices)[0].colG - (*vertices)[1].colG) / difference;
            step[0].b = ((*vertices)[0].colB - (*vertices)[1].colB) / difference;
        }
        if ((*vertices)[0].posY != (*vertices)[2].posY) {
            float difference = (*vertices)[0].posY - (*vertices)[2].posY;
            step[1].x = ((*vertices)[0].posX - (*vertices)[2].posX) / difference;
            step[1].r = ((*vertices)[0].colR - (*vertices)[2].colR) / difference;
            step[1].g = ((*vertices)[0].colG - (*vertices)[2].colG) / difference;
            step[1].b = ((*vertices)[0].colB - (*vertices)[2].colB) / difference;
        }
        if ((*vertices)[1].posY != (*vertices)[2].posY) {
            float difference = (*vertices)[1].posY - (*vertices)[2].posY;
            step[2].x = ((*vertices)[1].posX - (*vertices)[2].posX) / difference;
            step[2].r = ((*vertices)[1].colR - (*vertices)[2].colR) / difference;
            step[2].g = ((*vertices)[1].colG - (*vertices)[2].colG) / difference;
            step[2].b = ((*vertices)[1].colB - (*vertices)[2].colB) / difference;
        }

        size_t stride = (abs(info_header->biWidth) * 3 + 3) & 0xfffffffc;
        LONG min_y = (*vertices)[0].posY, max_y = (*vertices)[2].posY;
        if (min_y < 0) {
            min_y = 0;
        }
        if (max_y >= abs(info_header->biHeight)) {
            max_y = abs(info_header->biHeight) - 1;
        }

        for (LONG i = min_y; i <= max_y; i++) {
            struct VERTEXDATA left = {}, right = {};
            if (i <= (*vertices)[1].posY) {
                left.posX = round((*vertices)[0].posX + (i - (*vertices)[0].posY) * step[0].x);
                left.colR = round((*vertices)[0].colR + (i - (*vertices)[0].posY) * step[0].r);
                left.colG = round((*vertices)[0].colG + (i - (*vertices)[0].posY) * step[0].g);
                left.colB = round((*vertices)[0].colB + (i - (*vertices)[0].posY) * step[0].b);
            } else {
                left.posX = round((*vertices)[1].posX + (i - (*vertices)[1].posY) * step[2].x);
                left.colR = round((*vertices)[1].colR + (i - (*vertices)[1].posY) * step[2].r);
                left.colG = round((*vertices)[1].colG + (i - (*vertices)[1].posY) * step[2].g);
                left.colB = round((*vertices)[1].colB + (i - (*vertices)[1].posY) * step[2].b);
            }
            right.posX = round((*vertices)[0].posX + (i - (*vertices)[0].posY) * step[1].x);
            right.colR = round((*vertices)[0].colR + (i - (*vertices)[0].posY) * step[1].r);
            right.colG = round((*vertices)[0].colG + (i - (*vertices)[0].posY) * step[1].g);
            right.colB = round((*vertices)[0].colB + (i - (*vertices)[0].posY) * step[1].b);
            if (left.posX > right.posX) {
                swap_vertices(&left, &right);
            }
            struct COLORSTEP {
                float r, g, b;
            } line_color_step = {};
            if (left.posX != right.posX) {
                float difference = left.posX - right.posX;
                line_color_step.r = ((SHORT)left.colR - right.colR) / difference;
                line_color_step.g = ((SHORT)left.colG - right.colG) / difference;
                line_color_step.b = ((SHORT)left.colB - right.colB) / difference;
            }
            if (left.posX < 0) {
                left.posX = 0;
            }
            if (right.posX >= abs(info_header->biWidth)) {
                right.posX = abs(info_header->biWidth) - 1;
            }
            for (LONG j = left.posX; j <= right.posX; j++) {
                BYTE *pixel_address = image_data + i * stride + j * 3;
                pixel_address[0] = left.colB + (j - left.posX) * line_color_step.b;
                pixel_address[1] = left.colG + (j - left.posX) * line_color_step.g;
                pixel_address[2] = left.colR + (j - left.posX) * line_color_step.r;
            }
        }
    }
}

void print_help(void)
{
    puts("[Interactive RGB triangle drawing]");
    puts("Use one of the following commands:");
    puts("  help             prints this message");
    puts("  draw vertices    draws specified triangle on the bitmap");
    puts("                    the format of vertices is straightforward:");
    puts("                    x1 y1 color1 x2 y2 color2 x3 y3 color3");
    puts("  clear [color]    clears the bitmap (the default color is white)");
    puts("  save [filename]  saves the bitmap to a file");
    puts("  kill             quits the program without saving");
    puts("  quit             quits the program saving bitmap to the default location\n");
    puts("Supported color formats:");
    puts("  #rrggbb          (hexadecimal, 00-ff each)");
    puts("  red green blue   (decimal, 0-255 each)\n");
    puts("Examples:");
    puts("  draw 15 5 #000000 5 10 #000000 25 15 #000000");
    puts("  clear 255 0 0");
    puts("  save triangle.bmp\n");
}

int main(int argc, char **argv)
{
    //settings
    LONG image_width = 256,
        image_height = 256;
    char output_filename[260];
    strncpy(output_filename, "result.bmp", 260);
    
    //data-related variables created based on user-defined values
    BYTE file_header[14];
    struct BITMAPINFOHEADER info_header;
    BYTE *image_data;

    //parsing command-line parameters
    switch (argc) {
        case 1: {
            break;
        }
        case 4: {
            image_width = atoi(argv[2]);
            image_height = atoi(argv[3]);
        }
        case 2: {
            strncpy(output_filename, argv[1], 260);
            break;
        }
        default: {
            fputs("Usage: rgb_triangle [output_filename [bitmap_width bitmap_height]]", stderr);
            exit(EXIT_FAILURE);
        }
    }
    puts("Settings:");
    printf("  default output filename: %.260s\n", output_filename);
    printf("  bitmap size: %dx%d\n\n", image_width, image_height);

    print_help();

    //setting the data-related variables
    set_info_header(&info_header, image_width, image_height);
    DWORD image_data_size = ((abs(image_width) * 3 + 3) & 0xfffffffc) * abs(image_height);
    DWORD summed_header_size = sizeof(file_header) + sizeof(info_header);
    set_file_header(&file_header, image_data_size + summed_header_size, summed_header_size);
    image_data = malloc(image_data_size * sizeof(BYTE));

    //set background
    clear_bitmap(image_data, &info_header, 0xff, 0xff, 0xff);

    char buffer[512];
    //main loop
    while (true) {
        putchar('>');
        fgets(buffer, 512, stdin);
        buffer[511] = 0;
        size_t input_length = strlen(buffer);

        char comparison_buffer[6] = {0, 0, 0, 0, 0, 0};
        if (input_length < 4) {
            puts("Incorrect command!");
            continue;
        }
        memcpy(comparison_buffer, buffer, 4);
        if (input_length > 4) {
            comparison_buffer[4] = buffer[4];
        }
        for (int i = 0; i < 5; i++) {
            if (isspace(comparison_buffer[i])) {
                comparison_buffer[i] = 0;
                break;
            }
        }
        if (strcmp(comparison_buffer, "help") == 0) {
            print_help();
        } else if (strcmp(comparison_buffer, "draw") == 0) {
            bool status_ok = false;
            struct VERTEXDATA vertex_data[3];
            LONG colors[9];
            int values_read = sscanf(buffer, "draw %d %d #%2hhx%2hhx%2hhx %d %d #%2hhx%2hhx%2hhx %d %d #%2hhx%2hhx%2hhx",
                &vertex_data[0].posX, &vertex_data[0].posY, &vertex_data[0].colR, &vertex_data[0].colG,
                &vertex_data[0].colB, &vertex_data[1].posX, &vertex_data[1].posY, &vertex_data[1].colR,
                &vertex_data[1].colG, &vertex_data[1].colB, &vertex_data[2].posX, &vertex_data[2].posY,
                &vertex_data[2].colR, &vertex_data[2].colG, &vertex_data[2].colB);
            if (values_read == 15) {
                status_ok = true;
            } else {
                values_read = sscanf(buffer, "draw %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d",
                    &vertex_data[0].posX, &vertex_data[0].posY, &colors[0], &colors[1], &colors[2],
                    &vertex_data[1].posX, &vertex_data[1].posY, &colors[3], &colors[4], &colors[5],
                    &vertex_data[2].posX, &vertex_data[2].posY, &colors[6], &colors[7], &colors[8]);
                if (values_read == 15) {
                    status_ok = true;
                    for (size_t i = 0; i < 9; i++) {
                        if (colors[i] < 0 || colors[i] > 255) {
                            status_ok = false;
                            break;
                        }
                    }
                }
                if (status_ok) {
                    set_vertex(&vertex_data[0], vertex_data[0].posX, vertex_data[0].posY, colors[0], colors[1], colors[2]);
                    set_vertex(&vertex_data[1], vertex_data[1].posX, vertex_data[1].posY, colors[3], colors[4], colors[5]);
                    set_vertex(&vertex_data[2], vertex_data[2].posX, vertex_data[2].posY, colors[6], colors[7], colors[8]);
                }
            }
            if (status_ok) {
                sort_vertices(&vertex_data);
                draw_triangle(image_data, &info_header, &vertex_data);
            } else {
                puts("Incorrect vertex format!");
            }
        } else if (strcmp(comparison_buffer, "clear") == 0) {
            struct RGBQUAD clear_color;
            if (input_length == 5) {
                bool status_ok = false;
                int values_read = sscanf(buffer, "clear #%2hhx%2hhx%2hhx",
                    &clear_color.rgbRed, &clear_color.rgbGreen, &clear_color.rgbBlue);
                if (values_read == 3) {
                    status_ok = true;
                } else {
                    int colors[3];
                    values_read = sscanf(buffer, "clear %d %d %d", &colors[0], &colors[1], &colors[2]);
                    if (values_read == 3) {
                        status_ok = true;
                        for (size_t i = 0; i < 3; i++) {
                            if (colors[i] < 0 || colors[i] > 255) {
                                status_ok = false;
                                break;
                            }
                        }
                    }
                    if (status_ok) {
                        clear_color.rgbRed = colors[0];
                        clear_color.rgbGreen = colors[1];
                        clear_color.rgbBlue = colors[2];
                    }
                }
                if (!status_ok) {
                    puts("Incorrect color format!");
                    clear_color.rgbRed = 255;
                    clear_color.rgbGreen = 255;
                    clear_color.rgbBlue = 255;
                }
            } else {
                clear_color.rgbRed = 255;
                clear_color.rgbGreen = 255;
                clear_color.rgbBlue = 255;
            }
            clear_bitmap(image_data, &info_header, clear_color.rgbRed, clear_color.rgbGreen, clear_color.rgbBlue);
        } else if (strcmp(comparison_buffer, "save") == 0) {
            char *filename = output_filename;
            char filename_buffer[260];
            if (sscanf(buffer, "save %259[^\n]", filename_buffer) == 1) {
                filename = filename_buffer;
            }
            FILE *output_file = fopen(filename, "wb");
            fwrite(file_header, 1, sizeof(file_header), output_file);
            fwrite(&info_header, 1, sizeof(info_header), output_file);
            fwrite(image_data, 1, image_data_size, output_file);
            fclose(output_file);
        } else if (strcmp(comparison_buffer, "kill") == 0) {
            break;
        } else if (strcmp(comparison_buffer, "quit") == 0) {
            FILE *output_file = fopen(output_filename, "wb");
            fwrite(file_header, 1, sizeof(file_header), output_file);
            fwrite(&info_header, 1, sizeof(info_header), output_file);
            fwrite(image_data, 1, image_data_size, output_file);
            fclose(output_file);
            break;
        } else {
            puts("Incorrect command!");
        }

        if (input_length > 0) {
            input_length--;
            if (buffer[input_length] != '\n') {
                int character = 0;
                while (character != '\n' && character != EOF) {
                    character = getchar();
                }
            }
        }
    }

    //deallocate bitmap data
    free(image_data);

    return 0;
}
