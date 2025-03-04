# OpenShift Versioned Nginx

A multi-version web application setup using TypeScript and Nginx, designed for OpenShift deployment.

## Project Structure

```
.
├── src/
│   ├── app.ts
│   ├── index.html
│   ├── v3.145.22/
│   │   ├── app.ts
│   │   └── index.html
│   └── v3.145.23/
│       ├── app.ts
│       └── index.html
├── dist/           # Generated after build
├── gulpfile.js
├── tsconfig.json
└── package.json
```

## Build Process

The project uses Gulp to:
- Compile TypeScript files
- Replace version placeholders with actual versions from package.json
- Copy HTML files
- Create version-specific directories in the dist folder

### Build Commands

```bash
# Install dependencies
npm install

# Build the project
gulp build
```

### Output Structure

After building, the `dist` directory will contain:

```
dist/
├── app.js              # Root level application
├── index.html         # Root level HTML
├── favicon.ico        # Site favicon
├── v3.145.22/        # Version-specific builds
│   ├── app.js
│   └── index.html
└── v3.145.23/
    ├── app.js
    └── index.html
```

## Deployment

To deploy a new version of the application, run the following command:

```powershell
./deploy.ps1
```

This will:
1. Read the version from `package.json`.
2. Log in to the OpenShift registry.
3. Build the Docker image.
4. Tag and push the Docker image to the OpenShift registry.
5. Verify the Docker image in the OpenShift registry.
6. Set the OpenShift project.
7. Delete existing resources if they exist.
8. Deploy the application to OpenShift.
9. Expose the service with a versioned hostname.

You can access the deployed versions at:
- `http://localhost-1-0-0/index.html`
- `http://localhost-1-0-1/index.html`
- etc.

### Creating the OpenShift Project

Ensure that the OpenShift project `testing-nginx-with-version` exists. If it does not exist, create it using the following command:

```sh
oc new-project testing-nginx-with-version
```

### Getting the OpenShift Registry URL

Get the OpenShift registry URL using the following command:

```sh
oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}'
```

### Logging in to the OpenShift Registry

Ensure you are logged in to the OpenShift registry using the following command:

```sh
docker login -u $(oc whoami) -p $(oc whoami -t) <registry-url>
```

### Changing PowerShell Execution Policy

If you encounter an error about running scripts being disabled, you need to change the PowerShell execution policy. Open PowerShell as an administrator and run the following command:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Release

To release a new version of the application, run the following command:

```powershell
npm run release
```

This will:
1. Update the version in `package.json`.
2. Build the Docker image.
3. Tag and push the Docker image to the OpenShift registry.
4. Deploy the new version to OpenShift.

## Building the Project

To build the project, run the following command:

```powershell
npm run build
```

This will:
1. Compile the TypeScript files.
2. Copy `index.html` to the `dist` folder.

## License

This project is licensed under the Educational Use License. You may use, copy, modify, and distribute this project for educational purposes only. For more information, see the [LICENSE](./LICENSE) file.
