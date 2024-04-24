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
// TODO: convert to a deterministic memory management trategy (i.e. not using malloc/free)

void *roc_alloc(size_t size, unsigned int alignment)
{

  return malloc(size);
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

// Offset utility
void *subtract_from_pointer(void *ptr)
{
  char *char_ptr = (char *)ptr; // Cast to char* to perform byte-wise arithmetic
  char_ptr -= 0x8;              // Subtract 8 bytes
  return (void *)char_ptr;      // Cast back to void* if needed
}

// Define the structure of the audio I/O buffer that Roc will work with
// Currently just a mono audio signal

struct RocList
{
  float *data;
  size_t len;
  size_t capacity;
};

// Define the structure of the Roc model
struct Model
{
  int count;
  struct RocList signal;
};

// Define the structure of the main Roc function
struct RocMain
{
  void *init;
  void *update;
};

struct CallbackUserData
{
  struct Model *model;
  void *update_rocMain;
  struct RocList *rocAudioBuffer;
};

// Roc data initialisers
// TODO: convert this to a Model struct
struct Model model;

struct RocList rocAudioBuffer;

// // Define the Roc function
extern void roc__mainForHost_1_exposed_generic(void *);
extern size_t roc__mainForHost_1_exposed_size();

// // Init
// // Arguments: return value from roc, callback, argument to callback?
extern void roc__mainForHost_0_caller(void *, void *, void *);
extern size_t roc__mainForHost_0_size();

// Define the Roc update function
extern void roc__mainForHost_1_caller(void *, void *, void *);
extern size_t roc__mainForHost_1_size();

// Update Task
extern void roc__mainForHost_2_caller(void *, void *, void *);
extern size_t roc__mainForHost_2_size();

// Effects
extern struct RocList roc_fx_getCurrentInBuffer();

// Audio loop callback function
static int callback(const void *in,
                    void *out,
                    unsigned long framesPerBuffer,
                    const PaStreamCallbackTimeInfo *timeInfo,
                    PaStreamCallbackFlags statusFlags,
                    void *userData)
{

  // Destructure the userData arg
  struct CallbackUserData *ud = (struct CallbackUserData *)userData;

  // Call the Roc closure to process audio buffers
  ud->rocAudioBuffer->data = (float *)in;
  ud->rocAudioBuffer->len = framesPerBuffer;
  ud->rocAudioBuffer->capacity = framesPerBuffer;
  // run the update function
  // CAUSING SEGFAULT
  roc__mainForHost_1_caller(ud->model, NULL, ud->update_rocMain);
  roc__mainForHost_2_caller(NULL, ud->update_rocMain, ud->model);

  // Copy the output from the Roc buffer to the audio codec output buffer
  // memcpy(out, model.data, framesPerBuffer * sizeof(float));

  // Release the output buffer
  // void *ptr = subtract_from_pointer(rocOut.data);
  // roc_dealloc(ptr, 0);

  return paContinue;
}

int main()
{

  // Initialise Roc
  size_t size = roc__mainForHost_1_exposed_size();
  void *rocMain = roc_alloc(size, 0);
  roc__mainForHost_1_exposed_generic(rocMain);
  roc__mainForHost_0_caller(NULL, &model, rocMain);

  size_t update_task_size = roc__mainForHost_2_size();
  void *update_rocMain = roc_alloc(update_task_size, 0);

  // Prepare arg for audio callback
  struct CallbackUserData *rocCallbackArgs = roc_alloc(sizeof(struct CallbackUserData), 0);
  rocCallbackArgs->model = &model;
  rocCallbackArgs->update_rocMain = update_rocMain,
  rocCallbackArgs->rocAudioBuffer = &rocAudioBuffer;

  // Initialise PortAudio
  PaError err;
  PaStream *stream;

  err = Pa_Initialize();
  if (err != paNoError)
  {
    fprintf(stderr, "PortAudio error: %s\n", Pa_GetErrorText(err));
    return 1;
  }

  // Open a stream for playback and recording
  err = Pa_OpenDefaultStream(&stream, NUM_CHANNELS, NUM_CHANNELS, paFloat32, SAMPLE_RATE, BLOCK_SIZE, callback, rocCallbackArgs);
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

// Pass the input buffer into Roc
struct RocList roc_fx_getCurrentInBuffer(void)
{
  return rocAudioBuffer;
}