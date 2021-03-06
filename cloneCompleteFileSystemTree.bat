@echo off
@rem chage page code to utf-8
rem bug: sometimes, "for /f "delima=" %%i in['dir ...']" echo %%i is different from dir ...
rem		for example, directory "グレイテスト・マキシム" will be change to "グレイテスト?マキシム"
rem fix: use chcp 65001, change code page to utf-8
chcp 65001

echo begin clone
date /t
time /t
@rem all directory paths are full and end without "\" && all driver marks are lower letters
set "drivers=a b c d e f g h i j k l m n o p q r s t u v w x y z"
@rem user dependent, set first
set "cloneRootDirectory=d:\cloneFileSystemTree"
set "cloneRootDirectory2=c:\cloneFileSystemTree"

@rem to run more than once, delete old file system tree
if exist "%cloneRootDirectory%" (
	rd /S /Q "%cloneRootDirectory%"
)
md "%cloneRootDirectory%"
if exist "%cloneRootDirectory2%" (
	rd /S /Q "%cloneRootDirectory2%"
)
md "%cloneRootDirectory2%"
for %%i in (%drivers%) do (
	if exist %%i: (
		call :clone "root","%%i:"
	)
)

date /t
time /t
echo clone end
@rem clear variables
set drivers=
set cloneRootDirectory=
set cloneRootDirectory2=
goto:eof


@rem @param %1 parent directory
@rem @param %2 current directory name
:clone 
setlocal
	@rem process input path
	rem bug: delete "" around firstParam=%1 to avoid %1 contians &, like "this & that"
	set "firstParam=%~1"
	set "secondParam=%~2"

	rem bug: using "" in set statement, avoid errors when %1 or %2 contains bracket
	if "%firstParam%"=="root" (
		set "currentDirectory=%secondParam%"
	) else (
		set "currentDirectory=%firstParam%\%secondParam%"
	)

	@rem use \\?\ magic prefix before driver mark c,d,etc to avoid long path more than 260 bytes
	@rem to preserve consistency, use \\?\ in specific command
	@rem echo>FILE is useful, md DIRECTORY is not useful
	@rem for insurance reasons, chagne Registry[only for windows 10]
	set "cloneCurrentDirectory=%cloneRootDirectory%\%currentDirectory::=%"
	set "cloneCurrentDirectory2=%cloneRootDirectory2%\%currentDirectory::=%"
	set "cloneFFile=%cloneCurrentDirectory%\%secondParam::=%_files.txt"
	set "cloneFFile2=%cloneCurrentDirectory2%\%secondParam::=%_files.txt"
	set "cloneDFile=%cloneCurrentDirectory%\%secondParam::=%_directories.txt"
	set "cloneDFile2=%cloneCurrentDirectory2%\%secondParam::=%_directories.txt"

	echo "%currentDirectory%"

	@rem filter
	if "%cloneRootDirectory%"=="%currentDirectory%" (
		goto:eof
	)
	if "%cloneRootDirectory2%"=="%currentDirectory%" (
		goto:eof
	)

	@rem  create clone directory
	if not exist "\\?\%cloneCurrentDirectory%" (
		md "\\?\%cloneCurrentDirectory%\"
	)
	if not exist "\\?\%cloneCurrentDirectory2%" (
		md "\\?\%cloneCurrentDirectory2%\"
	)

	@rem clone file names
	@rem avoid output "File Not Found" error
	rem bug: use \\?\ before directory name, OR sometimes "..." tail cause error
	dir /A-D-S "\\?\%currentDirectory%\" > nul 2>&1
	if %errorlevel% equ 0 (
		dir /A-D-S "\\?\%currentDirectory%\" > "\\?\%cloneFFile%"
		dir /A-D-S "\\?\%currentDirectory%\" > "\\?\%cloneFFile2%"
	)

	@rem recursively clone, nested clone directory names
	rem bug: using "" in brackts, avoid errors when %currentDirectory% contains bracket
	rem bug: using "" around parameters, avoid directory that contains bracket ; actually, all directories should be around ""
	for /f "delims=" %%i in ('dir /AD-S /B "\\?\%currentDirectory%\"') do (
		if not exist "\\?\%cloneDFile%" (
			dir /AD-S "\\?\%currentDirectory%\" > "\\?\%cloneDFile%"
		)
		if not exist "\\?\%cloneDFile2%" (
			dir /AD-S "\\?\%currentDirectory%\" > "\\?\%cloneDFile2%"
		)

		@rem bug: four % pass one, to balance between % and ! is hard, so tree /f directly
		echo "%%i" | findstr /C:"%%" > nul
		if errorlevel 1 (
			call :clone "%currentDirectory%","%%i"
		) else (
			tree /F "%currentDirectory%\%%i" > "%cloneCurrentDirectory%\%secondParam::=%_%%i_tree.txt"
			tree /F "%currentDirectory%\%%i" > "%cloneCurrentDirectory2%\%secondParam::=%_%%i_tree.txt"
		)
	) 

endlocal
goto:eof
