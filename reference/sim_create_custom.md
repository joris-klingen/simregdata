# Create a custom dataset template YAML

Writes a commented template file that you can edit to define a custom
dataset. After editing, register it with
[`sim_register()`](https://joris-klingen.github.io/simregdata/reference/sim_register.md).

## Usage

``` r
sim_create_custom(path)
```

## Arguments

- path:

  File path for the template (e.g. `"my_survey.yaml"`).

## Value

Invisibly, `path`.
