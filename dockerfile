FROM microsoft/iis as base
## Install dotnet 2.2.0 hosting pack
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'Continue'; $verbosePreference='Continue';"]
COPY ./dotnet /src/host 
#"C:/setup/dotnet-hosting-2.1.0-win.exe"
#ADD https://download.microsoft.com/download/9/1/7/917308D9-6C92-4DA5-B4B1-B4A19451E2D2/dotnet-hosting-2.1.0-win.exe "C:/setup/dotnet-hosting-2.1.0-win.exe"
#RUN start-process -Filepath "C:/setup/dotnet-hosting-2.1.0-win.exe" -ArgumentList @('/install', '/quiet', '/norestart') -Wait
RUN start-process -Filepath "C:/src/host/dotnet-hosting-2.1.0-win.exe" -ArgumentList @('/install', '/quiet', '/norestart') -Wait
RUN Remove-Item -Force "C:/src/host/dotnet-hosting-2.1.0-win.exe"
## End Install dotnet 2.1.0 hosting pack
## Build and Publish Web App
#FROM mcr.microsoft.com/windows/servercore:1607 AS installer
#FROM mcr.microsoft.com/dotnet/core/sdk:2.1 
#FROM microsoft/aspnetcore:2.1
#FROM microsoft/dotnet:2.2-sdk-nanoserver-1803 AS build
#FROM microsoft/dotnet:2.1-sdk AS build
##FROM microsoft/aspnetcore-build:2.1 AS build
#FROM mcr.microsoft.com/dotnet/core/sdk:2.2
#FROM microsoft/dotnet:2.1-aspnetcore-runtime AS base
FROM microsoft/dotnet:2.1.300-sdk AS build
WORKDIR /src

COPY ["WebApplication5/WebApplication5/WebApplication5.csproj","WebApplication5/"]
COPY ["WebApplication5/WebApplication5/WebApplication5.csproj", "WebApplication5/"]
RUN dotnet restore "WebApplication5/WebApplication5.csproj"
COPY . .
WORKDIR "/src/WebApplication5"
RUN dotnet build "WebApplication5.csproj" --no-restore --no-dependencies -c Release -o /app 
FROM build AS publish
RUN dotnet publish "WebApplication5.csproj" -c Release -o /publish
FROM base AS final
WORKDIR /inetpub/wwwroot/samplewebapp
## Create Web Site and Web Application
RUN Import-Module WebAdministration; \
    Remove-Website -Name 'Default Web Site'; \
    New-WebAppPool -Name 'ap-samplewebapp'; \
    Set-ItemProperty IIS:\AppPools\ap-samplewebapp -Name managedRuntimeVersion -Value ''; \
    Set-ItemProperty IIS:\AppPools\ap-samplewebapp -Name enable32BitAppOnWin64 -Value 0;  \
    Set-ItemProperty IIS:\AppPools\ap-samplewebapp -Name processModel.identityType -Value Service; \
    New-Website -Name 'samplewebapp' \
                -Port 80 -PhysicalPath 'C:\inetpub\wwwroot\samplewebapp' \
                -ApplicationPool 'ap-samplewebapp' -force
COPY --from=publish /publish .
EXPOSE 80