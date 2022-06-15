#!/bin/csh
#

# time
python  /home/user/vikram/DSA_utils/get_timestr.py > /mnt/nfs/website/time.dat
set tm=`cat time.dat`
sed "s/CTIME/${tm}/" tindex.html > tt
mv tt index.html
sed "s/CTIME/${tm}/" tadc.html > tt
mv tt adc.html
sed "s/CTIME/${tm}/" trfi.html > tt
mv tt rfi.html
sed "s/CTIME/${tm}/" tcorr.html > tt
mv tt corr.html
echo "here"
set oldtm=`echo ${tm}`

# meminfo
rm -rf /mnt/nfs/runtime/fullog.dat
touch /mnt/nfs/runtime/fullog.dat


while (1)

    # time
    python  /home/user/vikram/DSA_utils/get_timestr.py > /mnt/nfs/website/time.dat
    set tm=`cat time.dat`
    sed "s/${oldtm}/${tm}/" index.html > tt
    mv tt index.html
    sed "s/${oldtm}/${tm}/" adc.html > tt
    mv tt adc.html
    sed "s/${oldtm}/${tm}/" rfi.html > tt
    mv tt rfi.html
    sed "s/${oldtm}/${tm}/" corr.html > tt
    mv tt corr.html
    echo "here"
    set oldtm=`echo ${tm}`
    
    echo "Set time"
    
    # heimdall output
    /home/user/vikram/DSA_utils/plot_FRB_cands_once /mnt/nfs/data/heimdall/heimdall.cand

    echo "heimdalled"
    
    # ADC
    python /home/user/vikram/DSA_utils/adchists.py

    echo "adc'd"
    
    # RFI
    set fl=`ls -drt /mnt/nfs/data/slog*.fits | tail -n 1`
    python /home/user/vikram/DSA_utils/plot_spectrometer_log_once.py ${fl}

    echo "RFId"
    
    # correlator
    # assumes processes are running on dsa1-4 to put last integration on nfs
    python /home/user/vikram/DSA_utils/monitor_corr_once.py dsa1_mon.fits /mnt/nfs/website/COR/dsa1.png
    python /home/user/vikram/DSA_utils/monitor_corr_once.py dsa2_mon.fits /mnt/nfs/website/COR/dsa2.png
    python /home/user/vikram/DSA_utils/monitor_corr_once.py dsa3_mon.fits /mnt/nfs/website/COR/dsa3.png
    python /home/user/vikram/DSA_utils/monitor_corr_once.py dsa4_mon.fits /mnt/nfs/website/COR/dsa4.png

    echo "Correlated"
    
    # logs
    cp /mnt/nfs/runtime/*.log LOGS
    foreach fl (`ls -d LOGS/*.log`)
	mv $fl ${fl}.txt
    end

    echo "logged"


    # dspsr plots
    foreach fl (`ls -rtd /mnt/nfs/data/heimdall/*.fil`)

	set n = `echo $fl | sed 's/\_/ /' | sed 's/\.fil//' | awk '{print $2}'`
	set dm = `grep $n /mnt/nfs/data/heimdall/heimdall.cand | awk '{print $6}'`
	set wid = `grep $n /mnt/nfs/data/heimdall/heimdall.cand | awk '{print $4}'`
	set length = `python -c "print 400*1.31072e-4+0.000761*${dm}"`
	set nbins = `python -c "print int(${length}/1.31072e-4/2.**(${wid}-1))"`
	set snr = `grep $n /mnt/nfs/data/heimdall/heimdall.cand | awk '{print $1}'`
	
	dspsr ${fl} -D ${dm} -L ${length} -b ${nbins} -A -F 512 -c ${length} -O /home/user/vikram/scratch/testplots/${snr}_${dm}_${wid}
	psrplot -p freq+ /home/user/vikram/scratch/testplots/${snr}_${dm}_${wid}.ar -c y:win=1300:1510 -c x:unit=ms -D /mnt/nfs/website/IMGS/tmp.ps/cps
	convert -rotate 90 /mnt/nfs/website/IMGS/tmp.ps /mnt/nfs/website/IMGS/${snr}_${dm}_${wid}.png
	rm -f /mnt/nfs/website/IMGS/tmp.ps
	mv $fl ${fl}t

	sed "109i <a href='IMGS/${snr}_${dm}_${wid}.png' target='_blank'>${snr}_${dm}_${wid}.png</a><br>" index.html > tt
	mv tt index.html
	
    end
    echo "dspsr'd"

    # get dada full
    set f1=`ssh dsa1 "source ~/.bashrc; dada_dbmetric -k dcda 2>&1 >/dev/null | sed 's/\,/ /' | sed 's/\,/ /'" | awk '{print $2}'`
    set f2=`ssh dsa2 "source ~/.bashrc; dada_dbmetric -k dcda 2>&1 >/dev/null | sed 's/\,/ /' | sed 's/\,/ /'" | awk '{print $2}'`
    set f3=`ssh dsa3 "source ~/.bashrc; dada_dbmetric -k dcda 2>&1 >/dev/null | sed 's/\,/ /' | sed 's/\,/ /'" | awk '{print $2}'`
    set f4=`ssh dsa4 "source ~/.bashrc; dada_dbmetric -k dcda 2>&1 >/dev/null | sed 's/\,/ /' | sed 's/\,/ /'" | awk '{print $2}'`
    set f5=`ssh dsa5 "source ~/.bashrc; dada_dbmetric -k dbda 2>&1 >/dev/null | sed 's/\,/ /' | sed 's/\,/ /'" | awk '{print $2}'`
    set f6=`ssh dsa5 "source ~/.bashrc; dada_dbmetric -k eada 2>&1 >/dev/null | sed 's/\,/ /' | sed 's/\,/ /'" | awk '{print $2}'`
    echo $f1 $f2 $f3 $f4 $f5 $f6 >> /mnt/nfs/runtime/fullog.dat
    python /home/user/vikram/DSA_utils/plot_fullog.py
    
    
    cd ..
    rsync -a website/ dsa-storage:/var/www/html
    cd website

    echo "rsynced"
    
    #sleep 5
    
end
