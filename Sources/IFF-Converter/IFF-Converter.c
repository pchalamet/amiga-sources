

/**********************************/
/* IFF-Converter v2.0             */
/* (c)1993-1995 Sync/DreamDealers */
/**********************************/


#include <clib/intuition_protos.h>
#include <clib/exec_protos.h>

struct IntuitionBase *IntuitionBase;

/* ouverture de l'intuition.libray */

int main(int argc,char **argv)
{
  IntuitionBase=OpenLibrary("intuition.library",39);
}
