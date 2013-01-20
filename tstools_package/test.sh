#!/bin/bash
                            
ascii=( 
'			    ____                                 '
'               ____  , -- -        ---   -.                     '
'            (((   ((  ///   //     \\-\ \  )) ))                '
'        ///    ///  (( _        _   -- \\--     \\\ \)          '
'     ((( ==  ((  -- ((             ))  )- ) __   ))  )))        '
'      ((  (( -=   ((  ---  (          _ ) ---  ))   ))          '
'         (( __ ((    ()(((  \\  / ///     )) __ )))             '
'                \\_ (( __  |     | __  ) _ ))                   '
'                          ,|  |  |                              '
'                         `-._____,-                             '
'                         `--.___,--                             '
'                           |     |                              '
'                           |    ||                              ' 
'                           | ||  |                              '
'                 ,    _,   |   | |                              '
'        (  ((  ((((  /,| __|     |  ))))  )))  )  ))            '
'      (()))       __/ ||(    ,,     ((//\     )     ))))        ' 
'---((( ///_.___ _/    ||,,_____,_,,, (|\ \___.....__..  ))--ool '
'           ____/      |/______________| \/_/\__                 '
'          /                                \/_/|                '
'         /  |___|___|__                        ||     ___       '
'         \    |___|___|_                       |/\   /__/|      '
'         /      |   |                           \/   |__|/      '
'                                                                '
)
IFS='%'
source ./ts_functions.sh
bomb(){
for line in "${ascii[@]}"; do
	echo "$line"
	sleep 0.1s
done
figlet "                  BOOM!"
}
#bomb
check_valid_chars A
echo $?
check_valid_chars !!
echo $?
check_valid_chars AAA
echo $?
echo ================
check_valid_backup_dir 20130118-12345
echo $?
check_valid_backup_dir 20130118-12345-A
echo $?
check_valid_backup_dir 20130118-12345-AAA
echo $?
check_valid_backup_dir 20130118-12345-!!
echo $?
check_valid_backup_dir 20130118-12345-
echo $?

