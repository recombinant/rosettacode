// https://rosettacode.org/wiki/Use_another_language_to_call_a_function
#include <stdio.h>

extern int Query (char * Data, size_t * Length);

int main (int argc, char * argv [])
{
   char     Buffer [1024];
   size_t   Size = sizeof (Buffer);
   
   if (0 == Query (Buffer, &Size))
   {
      printf ("failed to call Query\n");
   }
   else
   {
      char * Ptr = Buffer;
      while (Size-- > 0) putchar (*Ptr++);
      putchar ('\n');
   }
}