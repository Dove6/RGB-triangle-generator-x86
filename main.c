#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <math.h>
#include <stdlib.h>
#include <stdbool.h>

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

struct RGBFLOATQUAD {
    float rgbBlue;
    float rgbGreen;
    float rgbRed;
    float rgbReserved;
};

struct VERTEXDATA {
    DWORD posX;
    DWORD posY;
    struct RGBQUAD color;
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

void set_vertex(struct VERTEXDATA *vertex, DWORD pos_x, DWORD pos_y, DWORD hex_color)
{
    if (vertex != NULL) {
        vertex->posX = pos_x;
        vertex->posY = pos_y;
        memcpy(&(vertex->color), &hex_color, 4);
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

void draw_triangle(BYTE *image_data, struct BITMAPINFOHEADER *info_header, struct VERTEXDATA (*vertex_data)[3])
{
    if (image_data != NULL && info_header != NULL && vertex_data != NULL) {
        float delta[3] = {0, 0, 0};
        if ((*vertex_data)[0].posY != (*vertex_data)[1].posY) {
            delta[0] = ((float)(*vertex_data)[0].posX - (*vertex_data)[1].posX) / ((float)(*vertex_data)[0].posY - (*vertex_data)[1].posY);
        }
        if ((*vertex_data)[0].posY != (*vertex_data)[2].posY) {
            delta[1] = ((float)(*vertex_data)[0].posX - (*vertex_data)[2].posX) / ((float)(*vertex_data)[0].posY - (*vertex_data)[2].posY);
        }
        if ((*vertex_data)[1].posY != (*vertex_data)[2].posY) {
            delta[2] = ((float)(*vertex_data)[1].posX - (*vertex_data)[2].posX) / ((float)(*vertex_data)[1].posY - (*vertex_data)[2].posY);
        }
        struct RGBFLOATQUAD color_delta[3] = {{0, 0, 0}, {0, 0, 0}, {0, 0, 0}};
        if ((*vertex_data)[0].color.rgbRed != (*vertex_data)[1].color.rgbRed) {
            color_delta[0].rgbRed = ((float)(*vertex_data)[0].color.rgbRed - (*vertex_data)[1].color.rgbRed) / ((float)(*vertex_data)[0].posY - (*vertex_data)[1].posY);
        }
        if ((*vertex_data)[0].color.rgbGreen != (*vertex_data)[1].color.rgbGreen) {
            color_delta[0].rgbGreen = ((float)(*vertex_data)[0].color.rgbGreen - (*vertex_data)[1].color.rgbGreen) / ((float)(*vertex_data)[0].posY - (*vertex_data)[1].posY);
        }
        if ((*vertex_data)[0].color.rgbBlue != (*vertex_data)[1].color.rgbBlue) {
            color_delta[0].rgbBlue = ((float)(*vertex_data)[0].color.rgbBlue - (*vertex_data)[1].color.rgbBlue) / ((float)(*vertex_data)[0].posY - (*vertex_data)[1].posY);
        }
        if ((*vertex_data)[0].color.rgbRed != (*vertex_data)[2].color.rgbRed) {
            color_delta[1].rgbRed = ((float)(*vertex_data)[0].color.rgbRed - (*vertex_data)[2].color.rgbRed) / ((float)(*vertex_data)[0].posY - (*vertex_data)[2].posY);
        }
        if ((*vertex_data)[0].color.rgbGreen != (*vertex_data)[2].color.rgbGreen) {
            color_delta[1].rgbGreen = ((float)(*vertex_data)[0].color.rgbGreen - (*vertex_data)[2].color.rgbGreen) / ((float)(*vertex_data)[0].posY - (*vertex_data)[2].posY);
        }
        if ((*vertex_data)[0].color.rgbBlue != (*vertex_data)[2].color.rgbBlue) {
            color_delta[1].rgbBlue = ((float)(*vertex_data)[0].color.rgbBlue - (*vertex_data)[2].color.rgbBlue) / ((float)(*vertex_data)[0].posY - (*vertex_data)[2].posY);
        }
        if ((*vertex_data)[1].color.rgbRed != (*vertex_data)[2].color.rgbRed) {
            color_delta[2].rgbRed = ((float)(*vertex_data)[1].color.rgbRed - (*vertex_data)[2].color.rgbRed) / ((float)(*vertex_data)[1].posY - (*vertex_data)[2].posY);
        }
        if ((*vertex_data)[1].color.rgbGreen != (*vertex_data)[2].color.rgbGreen) {
            color_delta[2].rgbGreen = ((float)(*vertex_data)[1].color.rgbGreen - (*vertex_data)[2].color.rgbGreen) / ((float)(*vertex_data)[1].posY - (*vertex_data)[2].posY);
        }
        if ((*vertex_data)[1].color.rgbBlue != (*vertex_data)[2].color.rgbBlue) {
            color_delta[2].rgbBlue = ((float)(*vertex_data)[1].color.rgbBlue - (*vertex_data)[2].color.rgbBlue) / ((float)(*vertex_data)[1].posY - (*vertex_data)[2].posY);
        }

        DWORD aligned_width = (abs(info_header->biWidth) + 3) & 0xfffffffc;

        for (DWORD i = (*vertex_data)[0].posY; i <= (*vertex_data)[1].posY; i++) {
            DWORD left = round((*vertex_data)[0].posX + (i - (*vertex_data)[0].posY) * delta[0]);
            DWORD right = round((*vertex_data)[0].posX + (i - (*vertex_data)[0].posY) * delta[1]);
            struct RGBQUAD left_color, right_color;
            left_color.rgbRed = round((*vertex_data)[0].color.rgbRed + (i - (*vertex_data)[0].posY) * color_delta[0].rgbRed);
            left_color.rgbGreen = round((*vertex_data)[0].color.rgbGreen + (i - (*vertex_data)[0].posY) * color_delta[0].rgbGreen);
            left_color.rgbBlue = round((*vertex_data)[0].color.rgbBlue + (i - (*vertex_data)[0].posY) * color_delta[0].rgbBlue);
            right_color.rgbRed = round((*vertex_data)[0].color.rgbRed + (i - (*vertex_data)[0].posY) * color_delta[1].rgbRed);
            right_color.rgbGreen = round((*vertex_data)[0].color.rgbGreen + (i - (*vertex_data)[0].posY) * color_delta[1].rgbGreen);
            right_color.rgbBlue = round((*vertex_data)[0].color.rgbBlue + (i - (*vertex_data)[0].posY) * color_delta[1].rgbBlue);
            if (left > right) {
                DWORD tmp = left;
                left = right;
                right = tmp;
                struct RGBQUAD tmp_color = left_color;
                left_color = right_color;
                right_color = tmp_color;
            }
            struct RGBFLOATQUAD line_color_delta = {0, 0, 0};
            if (left_color.rgbRed != right_color.rgbRed) {
                line_color_delta.rgbRed = ((float)left_color.rgbRed - right_color.rgbRed) / ((float)left - right);
            }
            if (left_color.rgbGreen != right_color.rgbGreen) {
                line_color_delta.rgbGreen = ((float)left_color.rgbGreen - right_color.rgbGreen) / ((float)left - right);
            }
            if (left_color.rgbBlue != right_color.rgbBlue) {
                line_color_delta.rgbBlue = ((float)left_color.rgbBlue - right_color.rgbBlue) / ((float)left - right);
            }
            for (DWORD j = left; j <= right; j++) {
                (image_data + (i * aligned_width + j) * 3)[0] = left_color.rgbBlue + (j - left) * line_color_delta.rgbBlue;
                (image_data + (i * aligned_width + j) * 3)[1] = left_color.rgbGreen + (j - left) * line_color_delta.rgbGreen;
                (image_data + (i * aligned_width + j) * 3)[2] = left_color.rgbRed + (j - left) * line_color_delta.rgbRed;
            }
        }
        for (DWORD i = (*vertex_data)[1].posY; i <= (*vertex_data)[2].posY; i++) {
            DWORD left = round((*vertex_data)[1].posX + (i - (*vertex_data)[1].posY) * delta[2]);
            DWORD right = round((*vertex_data)[0].posX + (i - (*vertex_data)[0].posY) * delta[1]);
            struct RGBQUAD left_color, right_color;
            left_color.rgbRed = round((*vertex_data)[1].color.rgbRed + (i - (*vertex_data)[1].posY) * color_delta[2].rgbRed);
            left_color.rgbGreen = round((*vertex_data)[1].color.rgbGreen + (i - (*vertex_data)[1].posY) * color_delta[2].rgbGreen);
            left_color.rgbBlue = round((*vertex_data)[1].color.rgbBlue + (i - (*vertex_data)[1].posY) * color_delta[2].rgbBlue);
            right_color.rgbRed = round((*vertex_data)[0].color.rgbRed + (i - (*vertex_data)[0].posY) * color_delta[1].rgbRed);
            right_color.rgbGreen = round((*vertex_data)[0].color.rgbGreen + (i - (*vertex_data)[0].posY) * color_delta[1].rgbGreen);
            right_color.rgbBlue = round((*vertex_data)[0].color.rgbBlue + (i - (*vertex_data)[0].posY) * color_delta[1].rgbBlue);
            if (left > right) {
                DWORD tmp = left;
                left = right;
                right = tmp;
                struct RGBQUAD tmp_color = left_color;
                left_color = right_color;
                right_color = tmp_color;
            }
            struct RGBFLOATQUAD line_color_delta = {0, 0, 0};
            if (left_color.rgbRed != right_color.rgbRed) {
                line_color_delta.rgbRed = ((float)left_color.rgbRed - right_color.rgbRed) / ((float)left - right);
            }
            if (left_color.rgbGreen != right_color.rgbGreen) {
                line_color_delta.rgbGreen = ((float)left_color.rgbGreen - right_color.rgbGreen) / ((float)left - right);
            }
            if (left_color.rgbBlue != right_color.rgbBlue) {
                line_color_delta.rgbBlue = ((float)left_color.rgbBlue - right_color.rgbBlue) / ((float)left - right);
            }
            for (DWORD j = left; j <= right; j++) {
                (image_data + (i * aligned_width + j) * 3)[0] = left_color.rgbBlue + (j - left) * line_color_delta.rgbBlue;
                (image_data + (i * aligned_width + j) * 3)[1] = left_color.rgbGreen + (j - left) * line_color_delta.rgbGreen;
                (image_data + (i * aligned_width + j) * 3)[2] = left_color.rgbRed + (j - left) * line_color_delta.rgbRed;
            }
        }
    }
}

int main(void)
{
    //user-defined variables
    LONG image_width = 256,
        image_height = 256;
    char output_filename[] = "result.bmp";
    
    //data-related variables created based on user-defined values
    BYTE file_header[14];
    struct BITMAPINFOHEADER info_header;
    BYTE *image_data;

    //setting the data-related variables
    set_info_header(&info_header, image_width, image_height);
    DWORD image_data_size = image_width * image_height * 3;
    DWORD summed_header_size = sizeof(file_header) + sizeof(info_header);
    set_file_header(&file_header, image_data_size + summed_header_size, summed_header_size);
    image_data = malloc(image_data_size * sizeof(BYTE));

    //set background
    memset(image_data, -1, image_data_size);

    //getting the needed input
    /* currently hard-coded */
    struct VERTEXDATA vertex_data[3];
    set_vertex(&vertex_data[0], 128, 10, 0xff0000);
    set_vertex(&vertex_data[1], 12, 250, 0x00ff00);
    set_vertex(&vertex_data[2], 245, 235, 0x0000ff);

    sort_vertices(&vertex_data);

    //drawing the triangle(s)
    draw_triangle(image_data, &info_header, &vertex_data);

    //writing the file
    FILE *output_file = fopen(output_filename, "wb");
    fwrite(file_header, 1, sizeof(file_header), output_file);
    fwrite(&info_header, 1, sizeof(info_header), output_file);
    fwrite(image_data, 1, image_data_size, output_file);
    fclose(output_file);

    //deallocate bitmap data
    free(image_data);

    return 0;
}
