# Get the version from package.json
$version = (Get-Content package.json | ConvertFrom-Json).version.Trim()
$sanitizedVersion = ($version -replace '\.', '-').Trim()

# Get the OpenShift registry URL
$registryUrl = (oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}').Trim()

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
$timestamp = (Get-Date -Format "yyyyMMddHHmmss").Trim()
$imageTag = "$version-$timestamp".Trim()
$fullImageName = "$registryUrl/$projectName/versioned-nginx:$imageTag".Trim()

Write-Output "Image name: $fullImageName"

# Tag Docker image with exact name
docker tag versioned-nginx:$version $fullImageName

Write-Output "Pushing Docker image to OpenShift registry..."
# Push the Docker image to the OpenShift registry
docker push $fullImageName

Write-Output "Setting OpenShift project..."
# Set the OpenShift project
oc project $projectName

# Get the cluster domain suffix
$clusterDomain = (oc get ingress.config.openshift.io cluster -o jsonpath='{.spec.domain}')
Write-Output "Cluster domain: $clusterDomain"

# Define unique hostname using project name and version with cluster domain
$hostname = "nginx-$sanitizedVersion-$projectName.$clusterDomain"

Write-Output "Updating deployment..."
# Check if deployment exists
$deploymentExists = oc get deployment nginx-$sanitizedVersion
if ($deploymentExists) {
    Write-Output "Updating existing deployment with image: $fullImageName"
    # Update existing deployment with new image
    oc set image deployment/nginx-$sanitizedVersion nginx-$sanitizedVersion=$fullImageName
    # Force rollout to ensure update
    oc rollout restart deployment/nginx-$sanitizedVersion
    
    # Update route if it exists
    $routeExists = oc get route nginx-$sanitizedVersion
    if ($routeExists) {
        oc delete route nginx-$sanitizedVersion
    }
    oc expose svc/nginx-$sanitizedVersion --hostname=$hostname
} else {
    Write-Output "Creating new deployment with image: $fullImageName"
    # Create new deployment
    oc new-app $fullImageName --name=nginx-$sanitizedVersion
    # Create route with proper hostname
    oc expose svc/nginx-$sanitizedVersion --hostname=$hostname
}

Write-Output "Waiting for rollout to complete..."
oc rollout status deployment/nginx-$sanitizedVersion --timeout=180s

Write-Output "Deployment complete. You can access the application at http://$hostname"
Write-Output "To verify the deployment, run: curl http://$hostname"

# Display route information
Write-Output "Route information:"
oc get route nginx-$sanitizedVersion -o jsonpath='{.spec.host}{"\n"}'

# Optional: List all routes in current namespace
Write-Output "Current routes in namespace $projectName" 
oc get routes
