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

void set_vertex(struct VERTEXDATA *vertex, LONG pos_x, LONG pos_y, DWORD hex_color)
{
    if (vertex != NULL) {
        vertex->posX = pos_x;
        vertex->posY = pos_y;
        vertex->colR = (hex_color >> 16) & 0xff;
        vertex->colG = (hex_color >> 8) & 0xff;
        vertex->colB = hex_color & 0xff;
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

        LONG aligned_width = (abs(info_header->biWidth) + 3) & 0xfffffffc;
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
                BYTE *pixel_address = image_data + (i * aligned_width + j) * 3;
                pixel_address[0] = left.colB + (j - left.posX) * line_color_step.b;
                pixel_address[1] = left.colG + (j - left.posX) * line_color_step.g;
                pixel_address[2] = left.colR + (j - left.posX) * line_color_step.r;
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
    set_vertex(&vertex_data[0], 128, -10, 0xff0000);
    set_vertex(&vertex_data[1], -12, 260, 0x00ff00);
    set_vertex(&vertex_data[2], 265, 235, 0x0000ff);

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
