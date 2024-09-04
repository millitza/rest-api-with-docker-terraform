# Use the official .NET 8.0 SDK image to build the application
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

# Set the working directory inside the container
WORKDIR /app

# Copy the .csproj file and restore dependencies
COPY *.csproj ./
RUN dotnet restore

# Copy the entire project and build the application in Release mode
COPY . ./
RUN dotnet publish weatherapi.csproj -c Release -o out

# Use the official ASP.NET Core Runtime image to run the application
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime

# Set the working directory inside the container
WORKDIR /app

# Copy the compiled application from the build stage to the runtime stage
COPY --from=build /app/out ./

# Expose port 80 for the application
EXPOSE 80

# Set the entry point for the container to run the application
ENTRYPOINT ["dotnet", "weatherapi.dll"]
