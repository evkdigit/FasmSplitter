;File splitter
;Evgeney Kupin Copyright (c) 21.06.2013
;It's free for any including commercial purposes


format PE GUI 4.0
entry start

include 'win32w.inc'


MAX_DIVIDED_FILE_VALUE	=  1073741824
MAX_ZERO_NUMBER 	=  3
MAX_DIVIDE_NUMBER	=  (1000 - 1)		 ;-)))))))))


IDR_MENU	    =  10
IDR_ICON_DATA	    =  11
IDR_ICON	    =  12
IDR_ABOUT_DIALOG    =  13

IDM_SPLIT	    =  40
IDM_MERGE	    =  41
IDM_EXIT	    =  42
IDM_ABOUT	    =  43

IDD_ABOUT_OK	    =  50

ID_DIV_NUMBER_EDIT    = 100
ID_DIV_NUMBER_UP_DOWN = 101
ID_DIV_NUMBER_STATIC  = 102
ID_SPLIT_PUSH_BUTTON  = 103
ID_MERGE_PUSH_BUTTON  = 104


section '.idata' import data readable writeable

  library kernel32,'KERNEL32.DLL',\
	  user32,'USER32.DLL',\
	  comdlg32, 'comdlg32.dll',\
	  comctl32, 'comctl32.dll'

  include 'api\kernel32.inc'
  include 'api\user32.inc'
  include 'api\comdlg32.inc'
  include 'api\comctl32.inc'

section '.data' data readable writeable

   WindowClass		TCHAR 'Win32FileSplitter',0
   WindowTitle		TCHAR 'File splitter',0
   EditClass		TCHAR 'EDIT',0
   StaticClass		TCHAR 'STATIC',0
   PushButtonClass	TCHAR 'BUTTON',0
   UpDownClass		TCHAR 'msctls_updown32',0

   FilterString 	TCHAR 'All',0,'*.*;',0,'Splited',0,'*.sld;',0,0

   FormatParamString	TCHAR '%s%s%d%s',0
   PercentString	TCHAR '%s',0
   PercentZeroString	TCHAR '%0',0
   DecimalDString	TCHAR 'd',0

   FormatFileString	TCHAR '%s%02d',0
   FileExtensionString	TCHAR '-zip-',0
   AppendString 	TCHAR '000000000',0
   ExtensionString	TCHAR '.sld',0

   DividerValueString	TCHAR 'Divider value:',0
   SplitButtonString	TCHAR 'Split',0
   MergeButtonString	TCHAR 'Merge',0

   WindWidth   dd  226
   WindHeight  dd  130

   wc WNDCLASSEX 0, CS_VREDRAW + CS_HREDRAW, WindowProc,0,0,\
		 NULL,NULL,NULL,COLOR_BTNFACE+1, NULL, WindowClass, 0
   msg MSG

section '.bss' readable writeable

   hWnd 		dd ?
   hDivNumberEditWnd	dd ?
   hDivNumberUpDownWnd	dd ?
   hDivNumberStatic	dd ?
   hSplitPushButton	dd ?
   hMergePushButton	dd ?

   PosX dd ?
   PosY dd ?

   dwZeroNumber 	dd ?

   strOpenFile		 OPENFILENAME	 ?
   cFileNameToBeSplited  TCHAR	256  dup(?)
   cFileNameSplited	 TCHAR	256  dup(?)
   cMergedFileName	 TCHAR	256  dup(?)
   cDedugOutput 	 TCHAR	256  dup(?)

section '.text' code readable executable

OlderZeroCheck:
	push	ebp
	mov	ebp, esp
	push	ebx esi edi

	invoke	lstrlen, cFileNameToBeSplited
	shl	eax, 1
	add	eax, cFileNameToBeSplited
	sub	eax, 10

       push    edi
	mov	edi, eax
	std
	mov	ecx, 10
	mov	ax, WORD[FileExtensionString]
	repne	scasw
	cld
	sub	ecx, 9
	neg	ecx
	mov	[dwZeroNumber], ecx
       pop     edi

	invoke	wsprintf, FormatFileString, FormatParamString, PercentString,\
		PercentZeroString, [dwZeroNumber], DecimalDString

	pop	edi esi ebx
	leave
	ret


proc MergeFile
 local hInputFile:DWORD, dwOutputFile:DWORD, dwBytesRead:DWORD,\
       dwBytesWritten:DWORD, hFindFile:DWORD, dwFileNumber:DWORD,\
       dwInputFileSize:DWORD, hGlobMem:DWORD, lpGlobMemPointer:DWORD,\
       strFindData:WIN32_FIND_DATA

	push	ebx esi edi

	call OlderZeroCheck

	mov	[dwFileNumber], 0
	lea	eax, [strFindData]
	invoke	RtlZeroMemory, eax, 40

	invoke	lstrcpy, cMergedFileName, cFileNameToBeSplited
	invoke	lstrlen, cMergedFileName
	shl	eax, 1
	add	eax, cMergedFileName
	sub	eax, 18
	mov	ecx, [dwZeroNumber]
	shl	ecx, 1
	sub	eax, ecx
	mov	WORD[eax], '.'
	mov	WORD[eax+8], 0

	invoke	CreateFile, cMergedFileName, GENERIC_WRITE,\
		      0, NULL, CREATE_ALWAYS,\
		      FILE_ATTRIBUTE_NORMAL, NULL
	mov	[dwOutputFile], eax

	invoke	lstrlen, cFileNameToBeSplited
	shl	eax, 1
	add	eax, cFileNameToBeSplited
	sub	eax, 8
	mov	ecx, [dwZeroNumber]
	shl	ecx, 1
	sub	eax, ecx
	mov	WORD[eax],0

	invoke	wsprintf, AppendString, FormatFileString+4, [dwFileNumber]
	invoke	lstrcat, cFileNameToBeSplited, AppendString
	invoke	lstrcat, cFileNameToBeSplited, ExtensionString

MERGE_FILE_PROC_LOOP:
	lea	eax, [strFindData]
	invoke	FindFirstFile, cFileNameToBeSplited, eax
	mov	[hFindFile], eax
	cmp	eax, INVALID_HANDLE_VALUE
	je	MERGE_FILE_PROC_LOOP_EXIT

	invoke	CreateFile, cFileNameToBeSplited, GENERIC_READ,\
		      0, NULL, OPEN_EXISTING,\
		      FILE_ATTRIBUTE_NORMAL, NULL
	mov	[hInputFile], eax

	invoke	GetFileSize, [hInputFile], NULL
	mov	[dwInputFileSize], eax

	invoke	GlobalAlloc, GMEM_MOVEABLE+GMEM_ZEROINIT, [dwInputFileSize]
	mov	[hGlobMem], eax
	invoke	GlobalLock, [hGlobMem]
	mov	[lpGlobMemPointer], eax

	lea	eax, [dwBytesRead]
	invoke	ReadFile, [hInputFile], [lpGlobMemPointer], [dwInputFileSize],\
		    eax, NULL

	lea	eax, [dwBytesWritten]
	invoke	WriteFile, [dwOutputFile], [lpGlobMemPointer], [dwBytesRead],\
		     eax, NULL

	invoke	lstrlen, cFileNameToBeSplited
	shl	eax, 1
	add	eax, cFileNameToBeSplited
	sub	eax, 8
	mov	ecx, [dwZeroNumber]
	shl	ecx, 1
	sub	eax, ecx
	mov	WORD[eax],0

	inc	[dwFileNumber]
	invoke	wsprintf, AppendString, FormatFileString+4, [dwFileNumber]
	invoke	lstrcat, cFileNameToBeSplited, AppendString
	invoke	lstrcat, cFileNameToBeSplited, ExtensionString

	invoke	GlobalUnlock, [hGlobMem]
	invoke	GlobalFree, [hGlobMem]
	invoke	CloseHandle, [hInputFile]

	invoke	FindClose, [hFindFile]
	jmp	MERGE_FILE_PROC_LOOP

MERGE_FILE_PROC_LOOP_EXIT:
	invoke	CloseHandle, [dwOutputFile]

	mov	[dwZeroNumber], MAX_ZERO_NUMBER
	invoke	wsprintf, FormatFileString, FormatParamString, PercentString,\
		PercentZeroString, [dwZeroNumber], DecimalDString
	pop	edi esi ebx
	ret
endp

proc SplitFile
 local hInputFile:DWORD, dwOutputFile:DWORD, dwBytesToCopy:DWORD,\
       hGlobMem:DWORD, lpGlobMemPointer:DWORD, dwBytesRead:DWORD,\
       dwBytesWritten:DWORD, dwDivNumber:DWORD, dwCutNumber:DWORD

	push	ebx esi edi

	invoke	lstrlen, cFileNameToBeSplited
	shl	eax, 1
	add	eax, cFileNameToBeSplited
	sub	eax, 6
	invoke	lstrcpy, FileExtensionString+2, eax
	mov	WORD[FileExtensionString+8], '-'
	mov	WORD[FileExtensionString+10], 0

	invoke	CreateFile, cFileNameToBeSplited, GENERIC_READ,\
		      0, NULL, OPEN_EXISTING,\
		      FILE_ATTRIBUTE_NORMAL, NULL
	mov	[hInputFile], eax

	invoke	SendMessage, [hDivNumberUpDownWnd], UDM_GETPOS ,0 ,0
	mov	[dwDivNumber], eax

	invoke	GetFileSize, [hInputFile], NULL
	cmp	eax, MAX_DIVIDED_FILE_VALUE
	ja	SPLIT_FILE_PROC_MAX_INPUT_SIZE_EXCEEDED

	xor	edx,edx
	div	[dwDivNumber]
	mov	[dwBytesToCopy], eax

	invoke	GlobalAlloc, GMEM_MOVEABLE+GMEM_ZEROINIT, [dwBytesToCopy]
	mov	[hGlobMem], eax
	invoke	GlobalLock, [hGlobMem]
	mov	[lpGlobMemPointer], eax

	mov	[dwDivNumber], 0
	mov	[dwCutNumber], 8
SPLIT_FILE_PROC_WRITE_LOOP:
	lea	eax, [dwBytesRead]
	invoke	ReadFile, [hInputFile], [lpGlobMemPointer], [dwBytesToCopy],\
		    eax, NULL
	cmp	[dwBytesRead], 0
	je	SPLIT_FILE_PROC_WRITE_LOOP_EXIT

	invoke	lstrlen, cFileNameToBeSplited
	shl	eax, 1
	add	eax, cFileNameToBeSplited
	sub	eax, [dwCutNumber]
	mov	WORD[eax],0
	push	DWORD[dwZeroNumber]
	pop	DWORD[dwCutNumber]
	shl	[dwCutNumber], 1
	add	[dwCutNumber], 18

	invoke	wsprintf, AppendString, FormatFileString, FileExtensionString, [dwDivNumber]
	inc	[dwDivNumber]
	invoke	lstrcat, cFileNameToBeSplited, AppendString
	invoke	lstrcat, cFileNameToBeSplited, ExtensionString

	invoke	CreateFile, cFileNameToBeSplited, GENERIC_WRITE,\
		      0, NULL, CREATE_ALWAYS,\
		      FILE_ATTRIBUTE_NORMAL, NULL
	mov	[dwOutputFile], eax

	lea	eax, [dwBytesWritten]
	invoke	WriteFile, [dwOutputFile], [lpGlobMemPointer], [dwBytesRead],\
		     eax, NULL

	invoke	CloseHandle, [dwOutputFile]

	mov	eax, [dwBytesToCopy]
	cmp	[dwBytesWritten], eax
	je	SPLIT_FILE_PROC_WRITE_LOOP

SPLIT_FILE_PROC_WRITE_LOOP_EXIT:

      ;  invoke  wsprintf, cDedugOutput, FormatString, [dwBytesRead]
      ;  invoke  MessageBox, 0, cDedugOutput, 0, MB_OK

	invoke	GlobalUnlock, [hGlobMem]
	invoke	GlobalFree, [hGlobMem]

SPLIT_FILE_PROC_MAX_INPUT_SIZE_EXCEEDED:
	invoke	CloseHandle, [hInputFile]
	pop	edi esi ebx
	ret
endp

proc AboutDialogProc hwnddlg,msg,wparam,lparam
	push	ebx esi edi
	cmp	[msg],WM_INITDIALOG
	je	ABOUT_DIALOG_PROC_INIT
	cmp	[msg],WM_COMMAND
	je	ABOUT_DIALOG_PROC_COMMAND
	cmp	[msg],WM_CLOSE
	je	ABOUT_DIALOG_PROC_CLOSE
	xor	eax,eax
	jmp	ABOUT_DIALOG_PROC_FINISH

  ABOUT_DIALOG_PROC_INIT:

	jmp	ABOUT_DIALOG_PROC_PROCESSED

  ABOUT_DIALOG_PROC_COMMAND:
	cmp	[wparam],BN_CLICKED shl 16 + IDD_ABOUT_OK
	je	ABOUT_DIALOG_PROC_CLOSE
	invoke	EndDialog,[hwnddlg],1
	jmp	ABOUT_DIALOG_PROC_PROCESSED

  ABOUT_DIALOG_PROC_CLOSE:
	invoke	EndDialog,[hwnddlg],0

  ABOUT_DIALOG_PROC_PROCESSED:
	mov	eax,1

  ABOUT_DIALOG_PROC_FINISH:
	pop	edi esi ebx
	ret
endp

start:
	invoke	InitCommonControls

	invoke	GetModuleHandle,0
	mov	[wc.hInstance],eax
	mov	[wc.cbSize], 12*4
	invoke	LoadIcon, [wc.hInstance], IDR_ICON
	mov	[wc.hIcon],eax
	invoke	LoadCursor,0,IDC_ARROW
	mov	[wc.hCursor],eax
	invoke	RegisterClassEx,wc
	test	eax,eax
	jz	START_END_LOOP

	invoke	GetSystemMetrics, SM_CXSCREEN
	sub	eax, [WindWidth]
	shr	eax, 1
	mov	[PosX], eax

	invoke	GetSystemMetrics, SM_CYSCREEN
	sub	eax, [WindHeight]
	shr	eax, 1
	mov	[PosY], eax

	invoke	LoadMenu, [wc.hInstance], IDR_MENU
	invoke	CreateWindowEx, 0, WindowClass, WindowTitle,\
		WS_VISIBLE+WS_DLGFRAME+WS_SYSMENU,\
		[PosX], [PosY], [WindWidth], [WindHeight],\
		NULL, eax, [wc.hInstance], NULL
	test	eax,eax
	jz	START_END_LOOP

	mov	[hWnd], eax
	invoke	ShowWindow, [hWnd], SW_SHOWNORMAL
	invoke	UpdateWindow, [hWnd]

  START_MSG_LOOP:
	invoke	GetMessage ,msg, NULL,0,0
	cmp	eax,1
	jb	START_END_LOOP
	jne	START_MSG_LOOP
	invoke	TranslateMessage,msg
	invoke	DispatchMessage,msg
	jmp	START_MSG_LOOP

  START_END_LOOP:
	invoke	ExitProcess,[msg.wParam]

proc WindowProc uses ebx esi edi, hwnd, wmsg, wparam, lparam

	cmp	[wmsg],WM_COMMAND
	je	WIN_PROC_COMMAND
	cmp	[wmsg],WM_DESTROY
	je	WIN_PROC_DESTROY
	cmp	[wmsg],WM_CREATE
	je	WIN_PROC_CREATE

  WIN_PROC_DEFAULT:
	invoke	DefWindowProc, [hwnd], [wmsg], [wparam], [lparam]
	jmp	WIN_PROC_FINISH

  WIN_PROC_CREATE:
	mov	[dwZeroNumber], MAX_ZERO_NUMBER

	invoke	wsprintf, FormatFileString, FormatParamString, PercentString,\
		PercentZeroString, [dwZeroNumber], DecimalDString

	mov	[strOpenFile.lStructSize], sizeof.OPENFILENAME
	push	[hwnd]
	pop	[strOpenFile.hwndOwner]
	mov	[strOpenFile.lpstrFilter], FilterString
	mov	[strOpenFile.nFilterIndex], 1
	mov	[strOpenFile.lpstrFile], cFileNameToBeSplited
	mov	[strOpenFile.nMaxFile], 256
	mov	[strOpenFile.Flags], OFN_EXPLORER+OFN_PATHMUSTEXIST+\
		    OFN_LONGNAMES+OFN_FILEMUSTEXIST+OFN_CREATEPROMPT

	invoke	CreateWindowEx, WS_EX_CLIENTEDGE, EditClass, 0,\
		      WS_VISIBLE + WS_CHILD + ES_NUMBER, 145, 10,\
		      50, 25, [hwnd], ID_DIV_NUMBER_EDIT,\
		      [wc.hInstance], NULL
	mov	[hDivNumberEditWnd], eax

	invoke	CreateWindowEx, 0, UpDownClass, 0,\
		      WS_VISIBLE + WS_CHILD + UDS_SETBUDDYINT,\
		      195, 10, 30, 25, [hwnd], ID_DIV_NUMBER_UP_DOWN,\
		      [wc.hInstance], NULL
	mov	[hDivNumberUpDownWnd], eax
	invoke	SendMessage, [hDivNumberUpDownWnd], UDM_SETBUDDY,\
		    [hDivNumberEditWnd], 0

	mov	ax, 2
	shl	eax, 16
	mov	ax, MAX_DIVIDE_NUMBER
	invoke	SendMessage, [hDivNumberUpDownWnd], UDM_SETRANGE, 0, eax
	invoke	SendMessage, [hDivNumberUpDownWnd], UDM_SETPOS, 0, 00002h

	invoke	CreateWindowEx, WS_EX_STATICEDGE, StaticClass,\
		      DividerValueString,\
		      WS_VISIBLE + WS_CHILD + SS_SIMPLE, 10, 10,\
		      130, 25, [hwnd], ID_DIV_NUMBER_STATIC,\
		      [wc.hInstance], NULL
	mov	[hDivNumberStatic], eax

	invoke	CreateWindowEx, 0, PushButtonClass, SplitButtonString,\
		      WS_VISIBLE + WS_CHILD + BS_DEFPUSHBUTTON, 10, 45,\
		      98, 30, [hwnd], ID_SPLIT_PUSH_BUTTON,\
		      [wc.hInstance], NULL
	mov	[hSplitPushButton], eax

	invoke	CreateWindowEx, 0, PushButtonClass, MergeButtonString,\
		      WS_VISIBLE + WS_CHILD + BS_DEFPUSHBUTTON, 113, 45,\
		      98, 30, [hwnd], ID_MERGE_PUSH_BUTTON,\
		      [wc.hInstance], NULL
	mov	[hMergePushButton], eax

	xor	eax, eax
	jmp	WIN_PROC_FINISH

  WIN_PROC_COMMAND:
	mov	eax, [wparam]
	and	eax, 0ffffh
	cmp	eax, ID_SPLIT_PUSH_BUTTON
	je	WIN_PROC_SPLIT
	cmp	eax, IDM_SPLIT
	je	WIN_PROC_SPLIT
	cmp	eax, ID_MERGE_PUSH_BUTTON
	je	WIN_PROC_MERGE
	cmp	eax, IDM_MERGE
	je	WIN_PROC_MERGE
	cmp	eax, IDM_ABOUT
	je	WIN_PROC_ABOUT
	cmp	eax, IDM_EXIT
	je	WIN_PROC_DESTROY
	jmp	WIN_PROC_DEFAULT

  WIN_PROC_SPLIT:
	invoke	GetOpenFileName, strOpenFile
	test	eax, eax
	jz	WIN_PROC_FINISH
	stdcall SplitFile
	jmp	WIN_PROC_FINISH

  WIN_PROC_MERGE:
	invoke	GetOpenFileName, strOpenFile
	test	eax, eax
	jz	WIN_PROC_FINISH
	stdcall MergeFile
	jmp	WIN_PROC_FINISH

  WIN_PROC_ABOUT:
	invoke	DialogBoxParam, [wc.hInstance], IDR_ABOUT_DIALOG,\
		      [hwnd], AboutDialogProc, 0
	jmp	WIN_PROC_FINISH

  WIN_PROC_DESTROY:
	invoke	PostQuitMessage, 0
	xor	eax,eax

  WIN_PROC_FINISH:
	ret
endp

section '.rsrc' resource data readable

  ; resource directory

  directory RT_MENU,menus,\
	    RT_ICON,icons,\
	    RT_GROUP_ICON,group_icons,\
	    RT_DIALOG,dialogs,\
	    RT_VERSION,versions

  ; resource subdirectories

  resource menus,\
	   IDR_MENU ,LANG_ENGLISH+SUBLANG_DEFAULT,main_menu

  resource icons,\
	   IDR_ICON_DATA ,LANG_NEUTRAL,icon_data

  resource group_icons,\
	   IDR_ICON ,LANG_NEUTRAL,main_icon

  resource dialogs,\
	   IDR_ABOUT_DIALOG ,LANG_ENGLISH+SUBLANG_DEFAULT,demonstration

  resource versions,\
	   1,LANG_NEUTRAL,version

  menu main_menu
       menuitem '&File',0,MFR_POPUP
		menuitem '&Split', IDM_SPLIT
		menuitem 'Merge', IDM_MERGE
		menuseparator
		menuitem 'E&xit', IDM_EXIT,MFR_END
       menuitem '&Help',0,MFR_POPUP + MFR_END
		menuitem '&About...', IDM_ABOUT,MFR_END

  icon main_icon,icon_data,'Splitter.ico'

  dialog demonstration,'About',5,5,170,50,WS_CAPTION+WS_POPUP+WS_SYSMENU+DS_MODALFRAME
    dialogitem 'STATIC',IDR_ICON, -1, 5,5,70,8,WS_VISIBLE+SS_ICON
    dialogitem 'STATIC','File split and merge utility',-1,35,5,90,8,WS_VISIBLE
    dialogitem 'STATIC','File splitter 1.0.3',-1,48,15,70,8,WS_VISIBLE
    dialogitem 'STATIC','Copyright (C) 21.06.2013',-1,35,25,100,8,WS_VISIBLE
    dialogitem 'STATIC','Evgeney Kupin',-1,50,35,70,8,WS_VISIBLE
    dialogitem 'BUTTON','OK',IDD_ABOUT_OK,120,30,45,15,WS_VISIBLE+WS_TABSTOP+BS_DEFPUSHBUTTON
  enddialog

  versioninfo version,VOS__WINDOWS32,VFT_APP,VFT2_UNKNOWN,LANG_ENGLISH+SUBLANG_DEFAULT,0,\
	      'FileDescription','File splitter 1.0.3',\
	      'LegalCopyright','It is free from www.net46.net, Evgeney Kupin',\
	      'FileVersion','1.0.3',\
	      'ProductVersion','1.0.3',\
	      'OriginalFilename','FileSplitter.exe'
