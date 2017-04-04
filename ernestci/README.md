## What's this

As ernest code is spread around different repos, is useful for us to run a centralized battery of integration tests on each of these repos. So we ensure ernest still works based on the current service changes.

## Set up centralized tests

```
machine:
  dependencies:
    pre:
      - mkdir -p $ROOTPATH
      - rm -rf $ROOTPATH/toolset/ && git clone git@github.com:ernestio/toolset.git $ROOTPATH/toolset/
      - cd $ROOTPATH/toolset/ernestci/ && bundle install
  test:
    override:
      - ruby $ROOTPATH/toolset/ernestci/run.rb .ernest-ci
```

Additionally you should add an empty .ernest-ci file it will be used to define repo::branch dependencies like:

```
api-gateway:master
ernest-cli:master
```

On the other hand we will need to setup an environment variable on the service circleci definiing a valid ernestio/ernest token, the name of this env var will be `CIRCLE_TOKEN`


