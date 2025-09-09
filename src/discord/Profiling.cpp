#include "Profiling.hpp"
#include <string>
#include <cstdio>
#include <cstring>
#include <mach/mach_time.h>

uint64_t GetTimeMsProfiling(void)
{
    static mach_timebase_info_data_t timebase = {0,0};
    if (timebase.denom == 0) {
        mach_timebase_info(&timebase);
    }
    uint64_t t = mach_absolute_time();
    uint64_t nanoseconds = t * timebase.numer / timebase.denom;
	
	// but we actually need milliseconds so
	return nanoseconds / 1000000;
}

struct ProfilingTask
{
	const char* what;
	uint64_t startTime;
};

#define MAX_PROFILES 16

static ProfilingTask g_profilingStack[MAX_PROFILES];
static int g_profilingStackIndex = 0;

void BeginProfiling(const char* what)
{
	if (g_profilingStackIndex >= MAX_PROFILES) {
		fprintf(stderr, "BeginProfiling: profiling stack over flow");
		return;
	}
	
	int depth = g_profilingStackIndex++;
	
	std::string padding(depth, '\t');
	fprintf(stderr, "%sTask \"%s\" started.\n", padding.c_str(), what);
	
	ProfilingTask& task = g_profilingStack[depth];
	task.what = what;
	task.startTime = GetTimeMsProfiling();
}

void EndProfiling()
{
	if (g_profilingStackIndex <= 0) {
		fprintf(stderr, "EndProfiling: profiling stack under flow");
		return;
	}
	
	int depth = --g_profilingStackIndex;
	ProfilingTask& task = g_profilingStack[depth];
	uint64_t currTime = GetTimeMsProfiling();
	uint64_t diff = currTime - task.startTime;
	
	std::string padding(depth, '\t');
	fprintf(stderr, "%sTask \"%s\" finished in %lld milliseconds.\n", padding.c_str(), task.what, diff);
}
