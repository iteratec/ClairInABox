# ClairInABox

The clair security scanner for docker images, as a self-contained build container.


## Configuration parameters
| environment name | meaning | required? |
| ------ | ------ | ------ |
| PROJECT_NAME | The name of the project to be scanned | yes |
| IMAGE_TO_SCAN | The ID of the docker image to be scanned. <br>Can be an ID from Docker Hub like `arminc/clair-db:2019-03-17` or an URI to your own repository | yes |
| IMAGE_TO_SCAN_REPO_URL | The URL for alternative Docker repository containing the image to be scanned (for login). | no - only of login is required |
| IMAGE_TO_SCAN_REPO_USERNAME | The username for the authentication to the alternative Docker repository | no - only of login is required |
| IMAGE_TO_SCAN_REPO_PASSWORD | The username for the authentication to the alternative Docker repository | no - only of login is required |
| THRESHOLD | The threshold of issue severity which will cause the build to fail (see [Official Clair Documentation](https://github.com/arminc/clair-scanner/blob/master/README.md)). <br/>Possible values are: 'Defcon1', 'Critical', 'High', 'Medium', 'Low', 'Negligible', 'Unknown' | no, default is "unknown" |
| WHITELIST | Provide a whitelist for approved CVE numbers as defined in [Clair Documentation](https://github.com/arminc/clair-scanner/blob/master/README.md#example-whitelist-yaml-file). The parameter expects the content in the described yaml format - including line breaks and indentation. | no |

## How to use the scanner

### How to run the scanner locally:
```
docker login ciab.docker.iteratec.io
docker run --rm -d -v /var/run/docker.sock:/var/run/docker.sock 
    -e PROJECT_NAME=<project name> 
    -e IMAGE_TO_SCAN=<scan image name>
    iteratec/claireinabox:latest
```

### How to run the scanner in GitLab-CI:

```
clair-scan:
  stage: test_security
  image: docker:stable
  dependencies:
  - docker-build
  script:
    # Read Whitelist content from file "whitelist.yaml" lying in the root of the same repository
    - export WHITELIST_CONTENT=`cat whitelist.yaml`
    - >
      docker run --rm -v /var/run/docker.sock:/var/run/docker.sock
      -e PROJECT_NAME=<your project>
      -e IMAGE_TO_SCAN_REPO_USERNAME=$CIAB_TARGET_REGISTRY_USERNAME
      -e IMAGE_TO_SCAN_REPO_PASSWORD=$CIAB_TARGET_REGISTRY_PASSWORD
      -e IMAGE_TO_SCAN_REPO_URL=$CIAB_TARGET_REGISTRY_URL
      -e WHITELIST="$WHITELIST_CONTENT"
      -e IMAGE_TO_SCAN=<your image URi> 
      iteratec/claireinabox:latest
```

**Note**
At least the passwords should be provide as secret GitLab environment parameters.


