#include <errno.h>
#include <signal.h>
#include <stdbool.h>
#include <stdio.h>
#include <portaudio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>
#include <math.h>
#include <execinfo.h>

#ifdef _WIN32
#else
#include <sys/shm.h>  // shm_open
#include <sys/mman.h> // for mmap
#include <signal.h>   // for kill
#endif

#define SAMPLE_RATE 44100
#define BLOCK_SIZE 256
#define NUM_CHANNELS 1 // Adjust for mono (1) or stereo (2)

// Roc memory management

void *roc_alloc(size_t size, unsigned int alignment)
{

  void *ptr = malloc(size);
  printf("Memory allocated: %zu\n", (void *)ptr);
  return ptr;
}

void *roc_realloc(void *ptr, size_t new_size, size_t old_size, unsigned int alignment)
{
  return realloc(ptr, new_size);
}

void roc_dealloc(void *ptr, unsigned int alignment)
{
  // printf("Memory deallocated: %zu\n", ptr);
  free(ptr);
}

void roc_panic(void *ptr, unsigned int alignment)
{
  char *msg = (char *)ptr;
  fprintf(stderr,
          "Application crashed with message\n\n    %s\n\nShutting down\n", msg);
  exit(1);
}

// Roc debugging
void roc_dbg(char *loc, char *msg, char *src)
{
  fprintf(stderr, "[%s] %s = %s\n", loc, src, msg);
}

void *roc_memset(void *str, int c, size_t n)
{
  return memset(str, c, n);
}

int roc_shm_open(char *name, int oflag, int mode)
{
#ifdef _WIN32
  return 0;
#else
  return shm_open(name, oflag, mode);
#endif
}

void *roc_mmap(void *addr, int length, int prot, int flags, int fd, int offset)
{
#ifdef _WIN32
  return addr;
#else
  return mmap(addr, length, prot, flags, fd, offset);
#endif
}

int roc_getppid()
{
#ifdef _WIN32
  return 0;
#else
  return getppid();
#endif
}

// Define the structure of the audio I/O buffer the Roc will work
struct RocList
{
  float *data;
  size_t len;
  size_t capacity;
};

const size_t SLICE_BIT = ((size_t)1) << (8 * sizeof(size_t) - 1);
const size_t REFCOUNT_MAX = 0;

// Define the Roc function
extern void *roc__mainForHost_1_exposed_generic(struct RocList *outBuffer, struct RocList *inBuffer);

// Audio loop callback function
static int callback(const void *in,
                    void *out,
                    unsigned long framesPerBuffer,
                    const PaStreamCallbackTimeInfo *timeInfo,
                    PaStreamCallbackFlags statusFlags,
                    void *userData)
{

  size_t rc = REFCOUNT_MAX;
  size_t slice_bits = (((size_t)&rc) >> 1) | SLICE_BIT;

  // Declare Roc's input and output buffers
  struct RocList rocIn = {(float *)in, (size_t)framesPerBuffer, slice_bits};
  struct RocList rocOut;

  // Call the main Roc function
  // Currently leaking memory
  roc__mainForHost_1_exposed_generic(&rocOut, &rocIn);

  // Copy the output from the Roc buffer to the audio codec output buffer
  memcpy(out, rocOut.data, framesPerBuffer * sizeof(float));

  return paContinue;
}

int main()
{
  PaError err;
  PaStream *stream;

  // Initialize PortAudio
  err = Pa_Initialize();
  if (err != paNoError)
  {
    fprintf(stderr, "PortAudio error: %s\n", Pa_GetErrorText(err));
    return 1;
  }

  // Open a stream for playback and recording
  err = Pa_OpenDefaultStream(&stream, NUM_CHANNELS, NUM_CHANNELS, paFloat32, SAMPLE_RATE, BLOCK_SIZE, callback, NULL);
  if (err != paNoError)
  {
    fprintf(stderr, "PortAudio error: %s\n", Pa_GetErrorText(err));
    Pa_Terminate();
    return 1;
  }

  // Start, wait for user input, stop, close and terminate PortAudio
  err = Pa_StartStream(stream);
  if (err != paNoError)
  {
    fprintf(stderr, "PortAudio error: %s\n", Pa_GetErrorText(err));
    Pa_CloseStream(stream);
    Pa_Terminate();
    return 1;
  }
  printf("Press any key to stop...\n");
  getchar();
  err = Pa_StopStream(stream);
  if (err != paNoError)
  {
    fprintf(stderr, "PortAudio error: %s\n", Pa_GetErrorText(err));
  }
  Pa_CloseStream(stream);
  Pa_Terminate();

  return 0;
}