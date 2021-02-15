FROM mcr.microsoft.com/windows/servercore:ltsc2019

ARG OCTOPUSZIP

RUN powershell -Command \

  # Download software ; \

  copy-item ${OCTOPUSZIP} --Destination c:\${OCTOPUSZIP} ; \

  # Install Software ; \

  Expand-Archive -Path c:\${OCTOPUSZIP} -DestinationPath c:\octopus ; \

# Remove unneeded files ; \

  Remove-Item c:\${OCTOPUSZIP}