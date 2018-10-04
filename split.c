#include <stdio.h>
#include <errno.h>
void write(FILE *in, FILE *out) {
	char data[2048];
	fread(data, 2048,1, in);
	fwrite(data, 2048,1, out);
}

int main() {
	FILE *in  = fopen("rom", "rb");
	if(!in) {
		fprintf(stderr, "could not open rom, errno %i", (errno));
		return 3;
	}
	FILE *a = fopen("pinmame32_23/roms/dracula/cpu_u2.716", "wb");
	FILE *aa = fopen("u2.716", "wb");
	FILE *b = fopen("pinmame32_23/roms/dracula/cpu_u6.716", "wb");
	FILE *bb = fopen("u6.716", "wb");
	FILE *c = fopen("rom.764", "wb");
	fseek(in, 0x0000, SEEK_SET);
	write(in, a);
	fseek(in, 0x0000, SEEK_SET);
	write(in, aa);
	
	fseek(in, 2048, SEEK_SET);
	write(in, b);
	fseek(in, 2048, SEEK_SET);
	write(in, bb);

	fseek(in, 0x0000, SEEK_SET);
	write(in, c);
	write(in, c);
	fseek(in, 0x0000, SEEK_SET);
	write(in, c);
	write(in, c);
	
	fseek(in, 0x0000, SEEK_END);
	if(ftell(in)!=4096) {
		fprintf(stderr, "file overflow! %i", ftell(in));
		return 1;
	}
	fclose(a);
	fclose(b);
	fclose(c);
	fclose(in);
	return 0;
}