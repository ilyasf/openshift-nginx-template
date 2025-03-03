# Get the version from package.json
$version = (Get-Content package.json | ConvertFrom-Json).version
$sanitizedVersion = $version -replace '\.', '-'

# Get the OpenShift registry URL
$registryUrl = (oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')

# Define the project name
$projectName = "testing-nginx-with-version"

Write-Output "Logging in to OpenShift registry..."
# Log in to the OpenShift registry
docker login -u $(oc whoami) -p $(oc whoami -t) $registryUrl

Write-Output "Building Docker image versioned-nginx:$version..."
# Build the Docker image
docker build -t versioned-nginx:$version .

Write-Output "Tagging Docker image..."
# Tag the Docker image
docker tag versioned-nginx:$version $registryUrl/$projectName/versioned-nginx:$version

Write-Output "Pushing Docker image to OpenShift registry..."
# Push the Docker image to the OpenShift registry
docker push $registryUrl/$projectName/versioned-nginx:$version

Write-Output "Verifying Docker image in OpenShift registry..."
# Verify the Docker image is available in the OpenShift registry
if (!(docker images $registryUrl/$projectName/versioned-nginx:$version)) {
    Write-Error "Docker image not found in OpenShift registry. Exiting..."
    exit 1
}

Write-Output "Setting OpenShift project..."
# Set the OpenShift project
oc project $projectName

Write-Output "Deleting existing resources if they exist..."
# Delete existing resources if they exist
oc delete deployment nginx-$sanitizedVersion --ignore-not-found
oc delete service nginx-$sanitizedVersion --ignore-not-found
oc delete route nginx-$sanitizedVersion --ignore-not-found

Write-Output "Deploying application to OpenShift..."
# Deploy to OpenShift
oc new-app $registryUrl/$projectName/versioned-nginx:$version --name=nginx-$sanitizedVersion

Write-Output "Exposing service with versioned hostname..."
# Expose the service with a versioned hostname
oc expose svc/nginx-$sanitizedVersion --hostname=localhost-$sanitizedVersion

Write-Output "Deployment complete. You can access the application at http://localhost-$sanitizedVersion/index.html"
