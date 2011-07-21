#include <stdio.h>
#include <stdlib.h>
#include <string.h>


#define	DISASM_TABLE_SIZE	(512*1024)


struct T_DISASM
{
	unsigned long	ulAddr;
	unsigned long	ulInst;
	char			szLabel[128];
	char			szAsm[128];
};


T_DISASM	DisAsm_Table[DISASM_TABLE_SIZE];
int			DisAsm_Num = 0;


void ReadDisAsm(FILE * fp)
{
	char			szBuf[1024];
	char			szText[512];
	char			szLabel[512] = "";
	unsigned long	ulAddr;
	unsigned long	ulInst;
	int				iPos;
	bool			blText = false;

	while ( fgets(szBuf, sizeof(szBuf), fp) != NULL )
	{
		int iLen = strlen(szBuf);
		if ( szBuf[iLen-1] == '\n' ) { szBuf[iLen-1] = '\0'; }
		
		if ( strncmp(szBuf, "Disassembly of section", 22) == 0 )
		{
			blText = (strcmp(szBuf, "Disassembly of section .text:") == 0);
			continue;
		}

		if ( !blText )
		{
			szLabel[0] = '\0';
			continue;
		}
		
		// ラベル検出
		if ( sscanf(szBuf, "%x <%[_a-zA-Z0-9]>:", &ulAddr, szText) == 2 )
		{
			strcpy(szLabel, szText);
			continue;
		}
		
		// 逆汗部
		if ( sscanf(szBuf, "%lx:\t%lx\t%n", &ulAddr, &ulInst, &iPos) == 2 )
		{
			if ( DisAsm_Num < DISASM_TABLE_SIZE )
			{
				DisAsm_Table[DisAsm_Num].ulAddr = ulAddr;
				DisAsm_Table[DisAsm_Num].ulInst = ulInst;
				strcpy(DisAsm_Table[DisAsm_Num].szLabel, szLabel);
				strcpy(DisAsm_Table[DisAsm_Num].szAsm, &szBuf[iPos]);
				DisAsm_Num++;
			}
		}
	}
}


int main(int argc, char *argv[])
{
	FILE *fp;
	char	szBuf[1024];
	
	if ( argc < 3 )
	{
		return 1;
	}
	
	if ( (fp = fopen(argv[1], "r")) == NULL )
	{
		return 1;
	}
	ReadDisAsm(fp);
	fclose(fp);
	
	
	if ( (fp = fopen(argv[2], "r")) == NULL )
	{
		return 1;
	}
	while ( fgets(szBuf, sizeof(szBuf), fp) != NULL )
	{
		unsigned long	ulTime;
		char			cType;
		char			szText[256];
		unsigned long	ulAddr;
		unsigned long	ulInst;
		if ( (sscanf(szBuf, "%ld %s %c %lx %lx", &ulTime, szText, &cType, &ulAddr, &ulInst) == 5) && (cType == 'p') )
		{
			int iLen = strlen(szBuf);
			if ( szBuf[iLen-1] == '\n' ) { szBuf[iLen-1] = '\0'; }
			
			// 探索
			int i;
			for ( i = 0; i < DisAsm_Num; i++ )
			{
				if ( DisAsm_Table[i].ulAddr == ulAddr )
				{
					break;
				}
			}
			
			if (  i < DisAsm_Num )
			{
				printf("%s <%s> %08x %s\n", szBuf, DisAsm_Table[i].szLabel, DisAsm_Table[i].ulInst, DisAsm_Table[i].szAsm);
			}
			else
			{
				printf("%s\n", szBuf);
			}
		}
		else
		{
			printf("%s", szBuf);
		}
	}
	fclose(fp);
	
	
	return 0;
}

