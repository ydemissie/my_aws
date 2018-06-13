#! /usr/bin/bash
          resp=$(curl -s -S -g --insecure "https://52.39.45.190/api/?type=op&cmd=<show><chassis-ready></chassis-ready></show>&key=LUFRPT10VGJKTEV6a0R4L1JXd0ZmbmNvdUEwa25wMlU9d0N5d292d2FXNXBBeEFBUW5pV2xoZz09")
          echo $resp >> /tmp/pan.log
          if [[ $resp == *\"[CDATA[yes\"* ]] ; then
           break
          fi
          sleep 10s
          
  )