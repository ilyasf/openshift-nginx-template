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

Write-Output "Building Docker image versioned-nginx:$version with no-cache..."
# Build the Docker image with no-cache to ensure fresh build
docker build --no-cache -t versioned-nginx:$version .

Write-Output "Tagging Docker image..."
# Tag the Docker image with unique timestamp to force update
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$imageTag = "$version-$timestamp"
docker tag versioned-nginx:$version $registryUrl/$projectName/versioned-nginx:$imageTag

Write-Output "Pushing Docker image to OpenShift registry..."
# Push the Docker image to the OpenShift registry
docker push $registryUrl/$projectName/versioned-nginx:$imageTag

Write-Output "Setting OpenShift project..."
# Set the OpenShift project
oc project $projectName

# Define unique hostname using project name and version
$hostname = "$projectName-v$sanitizedVersion"

Write-Output "Updating deployment..."
# Check if deployment exists
$deploymentExists = oc get deployment nginx-$sanitizedVersion
if ($deploymentExists) {
    # Update existing deployment with new image
    oc set image deployment/nginx-$sanitizedVersion nginx-$sanitizedVersion=$registryUrl/$projectName/versioned-nginx:$imageTag
    # Force rollout to ensure update
    oc rollout restart deployment/nginx-$sanitizedVersion
    
    # Update route if it exists
    $routeExists = oc get route nginx-$sanitizedVersion
    if ($routeExists) {
        oc delete route nginx-$sanitizedVersion
    }
    oc expose svc/nginx-$sanitizedVersion --hostname=$hostname
} else {
    # Create new deployment
    oc new-app $registryUrl/$projectName/versioned-nginx:$imageTag --name=nginx-$sanitizedVersion
    # Create route with unique hostname
    oc expose svc/nginx-$sanitizedVersion --hostname=$hostname
}

Write-Output "Waiting for rollout to complete..."
oc rollout status deployment/nginx-$sanitizedVersion --timeout=180s

Write-Output "Deployment complete. You can access the application at http://$hostname/index.html"
Write-Output "To verify the deployment, run: curl http://$hostname/index.html"

# Optional: List all routes in current namespace
Write-Output "Current routes in namespace $projectName" 
oc get routes
