# Foo Bar

Foo Bar is a built-in template plugin for scaffolding WordPress plugins.

**Contributors:** [xwp](https://profiles.wordpress.org/xwp)  
**Requires at least:** 4.4  
**Tested up to:** 4.7.3  
**Stable tag:** trunk (master)  
**License:** [GPLv2 or later](http://www.gnu.org/licenses/gpl-2.0.html)  

## Description ##

Foo Bar is a built-in template plugin for scaffolding WordPress plugins. The [`bin/plugin`](../../../bin/plugin) bash script will copy the `foo-bar` plugin and make the necessary replacements via:

```bash
bin/plugin "Hello World"
```

This will create a plugin `hello-world` in the `wp-content/plugins` directory and will greatly speed up plugin development inside this repo.

Be sure to add your new plugin to the `testsuite` inside the [`wp-tests/phpunit.xml.dist`](../../../wp-tests/phpunit.xml.dist) file to ensure your PHPUnit tests are included in the `pre-commit` hook and `bin/phpunit` script. It is required that you run this script from this repositories root directory.
