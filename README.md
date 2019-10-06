Complete Homestead documentation https://laravel.com/docs/5.8/homestead.

## Installation

1. Install Homestead in the project directory
	```
	> composer install
	```
2. Fix folder mapping in `Homestead.yaml` to point to your project folder
    ```
    folders:
        -
            map:
    ```
3. Install and start the box
	```
	> vagrant up
	```

## Required tools
1. Composer (https://gist.github.com/tomysmile/3b37ab4a1ddd604093fe724d0a882166)
```
	> brew update
	> brew tap homebrew/dupes
	> brew tap homebrew/php
	> brew install php73
	> brew install composer
```

2. VirtualBox (https://www.virtualbox.org/wiki/Downloads)
	- http://www.digitesters.com/manage-a-virtualbox-headless-system-stop-and-remove-a-vm/
	
3. Vagrant (https://www.vagrantup.com/downloads.html)
	```
	// Reload vagrant box with updated Homestead.yaml configuration
	> vagrant reload --provision
	```

NOTE:
`Homestead.yaml` contains mappings to all sites. It's done so that one VM can be shared among several projects.
