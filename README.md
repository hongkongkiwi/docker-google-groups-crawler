# Google Groups Crawler Dockerfile

[Docker](http://docker.com) container to use [Google Groups Crawler](https://github.com/icy/google-group-crawler).

## Usage

### Install

Pull `hongkongkiwi/google-groups-crawler` from the Docker repository:

    docker pull hongkongkiwi/google-groups-crawler

Or build `hongkongkiwi/google-groups-crawler` from source:

    git clone https://github.com/hongkongkiwi/docker-google-groups-crawler.git
    cd docker-google-groups-crawler
    docker build -t hongkongkiwi/google-groups-crawler .

### Quick Start

If you are using a private group, first make sure you have a cookies.txt file which contains your login to google groups. You can use the instructions from the [Google Groups  Crawler]https://github.com/icy/google-group-crawler#private-group-or-group-hosted-by-an-organization) repo to get this. Put this file into the director you are mounting for config.

Run the image, binding associated ports, and mounting the present working
directory:

    docker run \
      -v $(pwd)/config:/config:ro -v $(pwd)/data:/data:rw \
      -e GOOGLE_GROUP_NAME='google-group-name' \
      -e GOOGLE_GROUP_ORG='your-org-name' \
      -ti hongkongkiwi/google-groups-crawler

<!-- ## Services

Service     | Port | Usage
------------|------|------
DocPad      | 9778 | When using `docpad run`, visit `http://localhost:9778` in your browser -->

<!-- ## Envrinoment Variables

Volume          | Description
----------------|-------------
`/config`       | The location of any additional configuration files (such as cookies.txt).
`/data`         | This is where your group data will be saved into. -->

## Volumes

Volume          | Description
----------------|-------------
`/config`       | The location of any additional configuration files (such as cookies.txt).
`/data`         | This is where your group data will be saved into.
