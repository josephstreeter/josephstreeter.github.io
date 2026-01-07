# Module Repositories

## Private Repositories

### BaGet

BaGet is...

The following Docker Compose file can be used to run BaGet.

```yaml
version: '3.7'
volumes:
  baget-data:
      name: baget-data
networks:
  internal-net:
    name: internal-net
    driver: bridge
services:
  baget:
    image: loicsharma/baget:latest
    container_name: baget
    restart: always
    environment:
      - ASPNETCORE_ENVIRONMENT=Production
      - Storage__Type=FileSystem
      - Storage__Path=/var/baget/packages
      - Database__Type=Sqlite
      - Database__ConnectionString=Data Source=/var/baget/baget.db
      - Search__Type=Database
      - ApiKey=MySecretApi
      - AllowPackageOverwrites=true
      - PackageDeletionBehavior=HardDelete
      - Mirror__Enabled=true
    volumes:
      - baget-data:/var/baget
    ports:
      - 5555:80
    networks: 
      - internal-net
```

The following command will register BaGet as a PSRepository:

```powershell
$Params = @{
    Name = "BaGet"
    SourceLocation = "http://localhost:5555/v3/index.json"
    PublishLocation = "http://localhost:5555/api/v2/package" 
    InstallationPolicy = "Trusted"
}

Register-PSRepository @Params 
```

The following commands used to find, install, upgrade, and remove a module from the BaGet PSRepository

```powershell
# Find a module
Find-Module -Name "ModuleName" -Repository "BaGet"

# Install module
Install-Module -Name "ModuleName" -Repository "BaGet"

# Update module
Update-Module -Name "ModuleName" -Repository "BaGet"

# Uninstall Module
Uninstall-Module -Name "ModuleName"
```

The ....
