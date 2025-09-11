#pragma once
#include <stdint.h>

#ifdef _DEBUG
#define ENABLE_PROFILING
#endif

#ifdef ENABLE_PROFILING

// Gets the current time in milliseconds since some arbitrary beginning point.
uint64_t GetTimeMsProfiling(void);

// Begins profiling a task.
//
// This supports recursion (i.e. multiple profilings happening at once)
void BeginProfiling(const char* what);

// Finishes profiling the current task.
void EndProfiling();

#else

#define BeginProfiling(x)

#define EndProfiling()

#endif

class Profiler
{
public:
	Profiler(const char* what)
	{
		BeginProfiling(what);
		dummy = 1;
	}
	
	~Profiler()
	{
		EndProfiling();
		dummy = 0;
	}
	
private:
	int dummy = 0;
};
