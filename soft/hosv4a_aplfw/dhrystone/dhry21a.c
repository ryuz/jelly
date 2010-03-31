/*
 *************************************************************************
 *
 *                   "DHRYSTONE" Benchmark Program
 *                   -----------------------------
 *
 *  Version:    C, Version 2.1
 *
 *  File:       dhry_1.c (part 2 of 3)
 *
 *  Date:       May 25, 1988
 *
 *  Author:     Reinhold P. Weicker
 *
 *************************************************************************
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "dhry.h"


#include "hosaplfw.h"
double dtime(void)
{
	return (double)Time_GetSystemTime() / 1000.0;
}


/* Global Variables: */

Rec_Pointer     Ptr_Glob,
                Next_Ptr_Glob;
int             Int_Glob;
Boolean         Bool_Glob;
char            Ch_1_Glob,
                Ch_2_Glob;
int             Arr_1_Glob [50];
int             Arr_2_Glob [50] [50];

char Reg_Define[] = "Register option selected.";

/*extern char     *malloc ();	*/
Enumeration     Func_1 ();
  /* forward declaration necessary since Enumeration may not simply be int */


#ifndef ROPT
#define REG
        /* REG becomes defined as empty */
        /* i.e. no register variables   */
#else
#define REG register
#endif

void Proc_1(REG Rec_Pointer);
void Proc_2 (One_Fifty *);
void Proc_3 (Rec_Pointer *);
void Proc_4 (void);
void Proc_5 (void);
#ifdef  NOSTRUCTASSIGN
 void memcpy (register char *, register char *, register int);
#endif

extern Boolean Func_2 (Str_30, Str_30);
extern void Proc_6 (Enumeration, Enumeration *);
extern void Proc_7 (One_Fifty, One_Fifty, One_Fifty *);
extern void Proc_8 (Arr_1_Dim, Arr_2_Dim, int, int);


/* variables for time measurement: */

#define Too_Small_Time 2
                /* Measurements should last at least 2 seconds */

double          Begin_Time,
                End_Time,
                User_Time;

double          Microseconds,
                Dhrystones_Per_Second,
                Vax_Mips;

/* end of variables for time measurement */


int dhrystone_main(int argc, char *argv[])
/*****/

  /* main program, corresponds to procedures        */
  /* Main and Proc_0 in the Ada version             */
{
        One_Fifty       Int_1_Loc;
  REG   One_Fifty       Int_2_Loc = 0;
        One_Fifty       Int_3_Loc;
  REG   char            Ch_Index;
        Enumeration     Enum_Loc;
        Str_30          Str_1_Loc;
        Str_30          Str_2_Loc;
  REG   int             Run_Index;
  REG   int             Number_Of_Runs;

/*        FILE            *Ap;	*/

  /* Initializations */
  /*
 #ifdef riscos
  if ((Ap = fopen("dhry/res","a+")) == NULL)
 #else
  if ((Ap = fopen("dhry.res","a+")) == NULL)
 #endif
    {
       StdIo_PrintFormat("Can not open dhry.res\n\n");
       exit(1);
    }
  */
  
  Next_Ptr_Glob = (Rec_Pointer) Memory_Alloc (sizeof (Rec_Type));
  Ptr_Glob = (Rec_Pointer) Memory_Alloc (sizeof (Rec_Type));

  Ptr_Glob->Ptr_Comp                    = Next_Ptr_Glob;
  Ptr_Glob->Discr                       = Ident_1;
  Ptr_Glob->variant.var_1.Enum_Comp     = Ident_3;
  Ptr_Glob->variant.var_1.Int_Comp      = 40;
  strcpy (Ptr_Glob->variant.var_1.Str_Comp,
          "DHRYSTONE PROGRAM, SOME STRING");
  strcpy (Str_1_Loc, "DHRYSTONE PROGRAM, 1'ST STRING");

  Arr_2_Glob [8][7] = 10;
        /* Was missing in published program. Without this statement,    */
        /* Arr_2_Glob [8][7] would have an undefined value.             */
        /* Warning: With 16-Bit processors and Number_Of_Runs > 32000,  */
        /* overflow may occur for this array element.                   */

  StdIo_PrintFormat ("\n");
  StdIo_PrintFormat ("Dhrystone Benchmark, Version 2.1 (Language: C)\n");
  StdIo_PrintFormat ("\n");
/*
  if (Reg)
  {
    StdIo_PrintFormat ("Program compiled with 'register' attribute\n");
    StdIo_PrintFormat ("\n");
  }
  else
  {
    StdIo_PrintFormat ("Program compiled without 'register' attribute\n");
    StdIo_PrintFormat ("\n");
  }
*/
/*
  StdIo_PrintFormat ("Please give the number of runs through the benchmark: ");
  {
    int n;
    scanf ("%d", &n);
    Number_Of_Runs = n;
  }
  StdIo_PrintFormat ("\n");
*/
  if ( argc >= 2 )
  {
    Number_Of_Runs = strtoul(argv[1], 0, 0);
  }
  else
  {
    Number_Of_Runs = 500000;
  }

  StdIo_PrintFormat ("Execution starts, %d runs through Dhrystone\n",Number_Of_Runs);

  /***************/
  /* Start timer */
  /***************/

  Begin_Time = dtime();

  for (Run_Index = 1; Run_Index <= Number_Of_Runs; ++Run_Index)
  {

    Proc_5();
    Proc_4();
      /* Ch_1_Glob == 'A', Ch_2_Glob == 'B', Bool_Glob == true */
    Int_1_Loc = 2;
    Int_2_Loc = 3;
    strcpy (Str_2_Loc, "DHRYSTONE PROGRAM, 2'ND STRING");
    Enum_Loc = Ident_2;
    Bool_Glob = ! Func_2 (Str_1_Loc, Str_2_Loc);
      /* Bool_Glob == 1 */
    while (Int_1_Loc < Int_2_Loc)  /* loop body executed once */
    {
      Int_3_Loc = 5 * Int_1_Loc - Int_2_Loc;
        /* Int_3_Loc == 7 */
      Proc_7 (Int_1_Loc, Int_2_Loc, &Int_3_Loc);
        /* Int_3_Loc == 7 */
      Int_1_Loc += 1;
    } /* while */
      /* Int_1_Loc == 3, Int_2_Loc == 3, Int_3_Loc == 7 */
    Proc_8 (Arr_1_Glob, Arr_2_Glob, Int_1_Loc, Int_3_Loc);
      /* Int_Glob == 5 */
    Proc_1 (Ptr_Glob);
    for (Ch_Index = 'A'; Ch_Index <= Ch_2_Glob; ++Ch_Index)
                             /* loop body executed twice */
    {
      if (Enum_Loc == Func_1 (Ch_Index, 'C'))
          /* then, not executed */
        {
        Proc_6 (Ident_1, &Enum_Loc);
        strcpy (Str_2_Loc, "DHRYSTONE PROGRAM, 3'RD STRING");
        Int_2_Loc = Run_Index;
        Int_Glob = Run_Index;
        }
    }
      /* Int_1_Loc == 3, Int_2_Loc == 3, Int_3_Loc == 7 */
    Int_2_Loc = Int_2_Loc * Int_1_Loc;
    Int_1_Loc = Int_2_Loc / Int_3_Loc;
    Int_2_Loc = 7 * (Int_2_Loc - Int_3_Loc) - Int_1_Loc;
      /* Int_1_Loc == 1, Int_2_Loc == 13, Int_3_Loc == 7 */
    Proc_2 (&Int_1_Loc);
      /* Int_1_Loc == 5 */

  } /* loop "for Run_Index" */

  /**************/
  /* Stop timer */
  /**************/

  End_Time = dtime();

  StdIo_PrintFormat ("Execution ends\n");
  StdIo_PrintFormat ("\n");
  StdIo_PrintFormat ("Final values of the variables used in the benchmark:\n");
  StdIo_PrintFormat ("\n");
  StdIo_PrintFormat ("Int_Glob:            %d\n", Int_Glob);
  StdIo_PrintFormat ("        should be:   %d\n", 5);
  StdIo_PrintFormat ("Bool_Glob:           %d\n", Bool_Glob);
  StdIo_PrintFormat ("        should be:   %d\n", 1);
  StdIo_PrintFormat ("Ch_1_Glob:           %c\n", Ch_1_Glob);
  StdIo_PrintFormat ("        should be:   %c\n", 'A');
  StdIo_PrintFormat ("Ch_2_Glob:           %c\n", Ch_2_Glob);
  StdIo_PrintFormat ("        should be:   %c\n", 'B');
  StdIo_PrintFormat ("Arr_1_Glob[8]:       %d\n", Arr_1_Glob[8]);
  StdIo_PrintFormat ("        should be:   %d\n", 7);
  StdIo_PrintFormat ("Arr_2_Glob[8][7]:    %d\n", Arr_2_Glob[8][7]);
  StdIo_PrintFormat ("        should be:   Number_Of_Runs + 10\n");
  StdIo_PrintFormat ("Ptr_Glob->\n");
  StdIo_PrintFormat ("  Ptr_Comp:          %d\n", (int) Ptr_Glob->Ptr_Comp);
  StdIo_PrintFormat ("        should be:   (implementation-dependent)\n");
  StdIo_PrintFormat ("  Discr:             %d\n", Ptr_Glob->Discr);
  StdIo_PrintFormat ("        should be:   %d\n", 0);
  StdIo_PrintFormat ("  Enum_Comp:         %d\n", Ptr_Glob->variant.var_1.Enum_Comp);
  StdIo_PrintFormat ("        should be:   %d\n", 2);
  StdIo_PrintFormat ("  Int_Comp:          %d\n", Ptr_Glob->variant.var_1.Int_Comp);
  StdIo_PrintFormat ("        should be:   %d\n", 17);
  StdIo_PrintFormat ("  Str_Comp:          %s\n", Ptr_Glob->variant.var_1.Str_Comp);
  StdIo_PrintFormat ("        should be:   DHRYSTONE PROGRAM, SOME STRING\n");
  StdIo_PrintFormat ("Next_Ptr_Glob->\n");
  StdIo_PrintFormat ("  Ptr_Comp:          %d\n", (int) Next_Ptr_Glob->Ptr_Comp);
  StdIo_PrintFormat ("        should be:   (implementation-dependent), same as above\n");
  StdIo_PrintFormat ("  Discr:             %d\n", Next_Ptr_Glob->Discr);
  StdIo_PrintFormat ("        should be:   %d\n", 0);
  StdIo_PrintFormat ("  Enum_Comp:         %d\n", Next_Ptr_Glob->variant.var_1.Enum_Comp);
  StdIo_PrintFormat ("        should be:   %d\n", 1);
  StdIo_PrintFormat ("  Int_Comp:          %d\n", Next_Ptr_Glob->variant.var_1.Int_Comp);
  StdIo_PrintFormat ("        should be:   %d\n", 18);
  StdIo_PrintFormat ("  Str_Comp:          %s\n", Next_Ptr_Glob->variant.var_1.Str_Comp);
  StdIo_PrintFormat ("        should be:   DHRYSTONE PROGRAM, SOME STRING\n");
  StdIo_PrintFormat ("Int_1_Loc:           %d\n", Int_1_Loc);
  StdIo_PrintFormat ("        should be:   %d\n", 5);
  StdIo_PrintFormat ("Int_2_Loc:           %d\n", Int_2_Loc);
  StdIo_PrintFormat ("        should be:   %d\n", 13);
  StdIo_PrintFormat ("Int_3_Loc:           %d\n", Int_3_Loc);
  StdIo_PrintFormat ("        should be:   %d\n", 7);
  StdIo_PrintFormat ("Enum_Loc:            %d\n", Enum_Loc);
  StdIo_PrintFormat ("        should be:   %d\n", 1);
  StdIo_PrintFormat ("Str_1_Loc:           %s\n", Str_1_Loc);
  StdIo_PrintFormat ("        should be:   DHRYSTONE PROGRAM, 1'ST STRING\n");
  StdIo_PrintFormat ("Str_2_Loc:           %s\n", Str_2_Loc);
  StdIo_PrintFormat ("        should be:   DHRYSTONE PROGRAM, 2'ND STRING\n");
  StdIo_PrintFormat ("\n");

  User_Time = End_Time - Begin_Time;

  if (User_Time < Too_Small_Time)
  {
    StdIo_PrintFormat ("Measured time too small to obtain meaningful results\n");
    StdIo_PrintFormat ("Please increase number of runs\n");
    StdIo_PrintFormat ("\n");
  }
  else
  {
    StdIo_PrintFormat ("User_Time:%d.%03d seconds\n", (int)User_Time, (int)(User_Time*1000));
    Microseconds = User_Time * Mic_secs_Per_Second
                        / (double) Number_Of_Runs;
    Dhrystones_Per_Second = (double) Number_Of_Runs / User_Time;
    Vax_Mips = Dhrystones_Per_Second / 1757.0;

#ifdef ROPT
    StdIo_PrintFormat ("Register option selected?  YES\n");
#else
    StdIo_PrintFormat ("Register option selected?  NO\n");
    strcpy(Reg_Define, "Register option not selected.");
#endif
    StdIo_PrintFormat ("Microseconds for one run through Dhrystone: ");
    StdIo_PrintFormat ("%d \n", (long)Microseconds);
    StdIo_PrintFormat ("Dhrystones per Second:                      ");
    StdIo_PrintFormat ("%d \n", (long)Dhrystones_Per_Second);
    StdIo_PrintFormat ("VAX MIPS rating = %d.%03d\n", (long)Vax_Mips, (long)(Vax_Mips*100));
    StdIo_PrintFormat ("\n");

/*
  fStdIo_PrintFormat(Ap,"\n");
  fStdIo_PrintFormat(Ap,"Dhrystone Benchmark, Version 2.1 (Language: C)\n");
  fStdIo_PrintFormat(Ap,"%s\n",Reg_Define);
  fStdIo_PrintFormat(Ap,"Microseconds for one loop: %7.1f\n",Microseconds);
  fStdIo_PrintFormat(Ap,"Dhrystones per second: %10.1f\n",Dhrystones_Per_Second);
  fStdIo_PrintFormat(Ap,"VAX MIPS rating: %10.3f\n",Vax_Mips);
  fclose(Ap);
*/

  }
  
  return 0;

}


void
Proc_1 (REG Rec_Pointer Ptr_Val_Par)
    /* executed once */
{
  REG Rec_Pointer Next_Record = Ptr_Val_Par->Ptr_Comp;
                                        /* == Ptr_Glob_Next */
  /* Local variable, initialized with Ptr_Val_Par->Ptr_Comp,    */
  /* corresponds to "rename" in Ada, "with" in Pascal           */

  structassign (*Ptr_Val_Par->Ptr_Comp, *Ptr_Glob);
  Ptr_Val_Par->variant.var_1.Int_Comp = 5;
  Next_Record->variant.var_1.Int_Comp
        = Ptr_Val_Par->variant.var_1.Int_Comp;
  Next_Record->Ptr_Comp = Ptr_Val_Par->Ptr_Comp;
  Proc_3 (&Next_Record->Ptr_Comp);
    /* Ptr_Val_Par->Ptr_Comp->Ptr_Comp
                        == Ptr_Glob->Ptr_Comp */
  if (Next_Record->Discr == Ident_1)
    /* then, executed */
  {
    Next_Record->variant.var_1.Int_Comp = 6;
    Proc_6 (Ptr_Val_Par->variant.var_1.Enum_Comp,
           &Next_Record->variant.var_1.Enum_Comp);
    Next_Record->Ptr_Comp = Ptr_Glob->Ptr_Comp;
    Proc_7 (Next_Record->variant.var_1.Int_Comp, 10,
           &Next_Record->variant.var_1.Int_Comp);
  }
  else /* not executed */
    structassign (*Ptr_Val_Par, *Ptr_Val_Par->Ptr_Comp);
} /* Proc_1 */


void
Proc_2 (One_Fifty *Int_Par_Ref)
/******************/
    /* executed once */
    /* *Int_Par_Ref == 1, becomes 4 */
{
  One_Fifty  Int_Loc;
  Enumeration   Enum_Loc = Ident_1;

  Int_Loc = *Int_Par_Ref + 10;
  do /* executed once */
    if (Ch_1_Glob == 'A')
      /* then, executed */
    {
      Int_Loc -= 1;
      *Int_Par_Ref = Int_Loc - Int_Glob;
      Enum_Loc = Ident_1;
    } /* if */
  while (Enum_Loc != Ident_1); /* true */
} /* Proc_2 */


void
Proc_3 (Rec_Pointer *Ptr_Ref_Par)
/******************/
    /* executed once */
    /* Ptr_Ref_Par becomes Ptr_Glob */
{
  if (Ptr_Glob != Null)
    /* then, executed */
    *Ptr_Ref_Par = Ptr_Glob->Ptr_Comp;
  Proc_7 (10, Int_Glob, &Ptr_Glob->variant.var_1.Int_Comp);
} /* Proc_3 */


void
Proc_4 (void) /* without parameters */
/*******/
    /* executed once */
{
  Boolean Bool_Loc;

  Bool_Loc = Ch_1_Glob == 'A';
  Bool_Glob = Bool_Loc | Bool_Glob;
  Ch_2_Glob = 'B';
} /* Proc_4 */


void
Proc_5 (void) 	/* without parameters */
		/* executed once */
{
  Ch_1_Glob = 'A';
  Bool_Glob = false;
} /* Proc_5 */


        /* Procedure for the assignment of structures,          */
        /* if the C compiler doesn't support this feature       */
#ifdef  NOSTRUCTASSIGN
void
memcpy (register char *d, register char *s, register int l)
/* register char   *d; register char   *s; register int    l; */
{
        while (l--) *d++ = *s++;
}
#endif
