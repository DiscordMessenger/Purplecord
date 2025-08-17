#include <string>
#include <cstdio>

extern "C" void Stuff()
{
	FILE* f = fopen("/var/mobile/Media/sup.txt", "w");
	
	std::string a = "cheese";
	std::string b = "banana";
	
	std::string c;
	
	try {
		c = a+b+b+a; //cheesebananabananacheese
		throw 1;
	}
	catch (int x) {
		fprintf(f, "%d", x);
		c = b+a+a+b; // bananacheesecheesebanana
	}
	
	fprintf(f, "%s\n", c.c_str());
	
	fclose(f);
}
