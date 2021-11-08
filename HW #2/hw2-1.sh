cat /var/log/auth.log |
    awk '{if($0 ~ /repeated/){for(i=1;i<=$9;i++){print f}} else{f=$0;print $0}}'|
    awk '/sudo/{
            if($0 ~ /COMMAND/){
                for (i=1;i<=NF;i++){
                    if ($i ~ /COMMAND=/){
                        command = $i;
                        for (j=i+1;j<=NF;j++){
                            command = command " " $j;
                        }
                    }
                }print "sudo " $1 " " $2 " " $3 " " $6 " " command
            }}/sshd/{if($0 !~/sudo/)print $0}' |
    awk -F "COMMAND=" '/sudo/{print $1 $2}/sshd/{if($0 !~/sudo/)print $0}' |
    awk '{  if($0 ~ /sudo/){
                command="";
                for(i=6;i<=NF;i++){
                    if(i==6){
                        command=command $i
                    }
                    else{
                        command=command " " $i
                    }
                }
                if($3<10){day = "0" $3}
                else{day=$3}
                if ($2 == "Jan"){print "1 " $5 " used sudo to do `" command "` on 2021-01-" day " " $4}
                else if ($2 == "Feb"){print "1 " $5 " used sudo to do `" command "` on 2021-02-" day " " $4}
                else if ($2 == "Mar"){print "1 " $5 " used sudo to do `" command "` on 2021-03-" day " " $4}
                else if ($2 == "Apr"){print "1 " $5 " used sudo to do `" command "` on 2021-04-" day " " $4}
                else if ($2 == "May"){print "1 " $5 " used sudo to do `" command "` on 2021-05-" day " " $4}
                else if ($2 == "Jun"){print "1 " $5 " used sudo to do `" command "` on 2021-06-" day " " $4}
                else if ($2 == "Jul"){print "1 " $5 " used sudo to do `" command "` on 2021-07-" day " " $4}
                else if ($2 == "Aug"){print "1 " $5 " used sudo to do `" command "` on 2021-08-" day " " $4}
                else if ($2 == "Sep"){print "1 " $5 " used sudo to do `" command "` on 2021-09-" day " " $4}
                else if ($2 == "Oct"){print "1 " $5 " used sudo to do `" command "` on 2021-10-" day " " $4}
                else if ($2 == "Nov"){print "1 " $5 " used sudo to do `" command "` on 2021-11-" day " " $4}
                else if ($2 == "Dec"){print "1 " $5 " used sudo to do `" command "` on 2021-12-" day " " $4}
            }
            else{
                if($0 ~ /error/){
                    if($0 !~ /illegal/){
                        user[$11]++;IP[$13]++;
                    }
                    else{
                        IP[$15]++;
                    }
                }
            }
        }
    END{
        for(key in user){
            if(user[key]>=1) print "2 " key " failed to log in " user[key] " times"
        }
        for(key in IP){
            if(IP[key]>=1) print "3 " key " failed to log in " IP[key] " times"}}' |
    awk '{output[1]="audit_sudo.txt"; output[2]="audit_user.txt"; output[3]="audit_ip.txt"; result=$2;
            for(i=3;i<=NF;i++){result = result " " $i} print result > output[$1]}'