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
source ts_functions.sh
bomb(){
for line in "${ascii[@]}"; do
	echo "$line"
	sleep 0.1s
done
}
bomb
