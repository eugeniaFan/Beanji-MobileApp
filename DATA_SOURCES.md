# Data Sources

Beanji includes a small bundled catalog of three common houseplants. The catalog was assembled specifically for this project and is not an export of a third-party API or dataset.

## Methodology

- Accepted scientific names were checked against Plants of the World Online by the Royal Botanic Gardens, Kew.
- General indoor care guidance was reviewed using the North Carolina Extension Gardener Plant Toolbox.
- Source descriptions are not reproduced. Plant descriptions were written specifically for Beanji in concise, original wording.
- General care guidance was normalized into Beanji-specific categories for watering needs, light requirements, and care difficulty.
- Watering intervals are simplified reminder defaults rather than exact biological requirements.
- Catalog information was last reviewed on August 22, 2026.

## Catalog entries

### Swiss Cheese Plant

- Scientific name: `Monstera deliciosa`
- Taxonomy: [Plants of the World Online](https://powo.science.kew.org/taxon/87478-1)
- General care reference: [North Carolina Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/monstera-deliciosa/)

### Snake Plant

- Scientific name: `Dracaena trifasciata`
- Taxonomy: [Plants of the World Online](https://powo.science.kew.org/taxon/urn%3Alsid%3Aipni.org%3Anames%3A77164235-1)
- General care reference: [North Carolina Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/dracaena-trifasciata/common-name/snake-plant/)
- Taxonomic note: The species was previously widely known as `Sansevieria trifasciata`.

### Golden Pothos

- Scientific name: `Epipremnum aureum`
- Taxonomy: [Plants of the World Online](https://powo.science.kew.org/taxon/87014-1)
- General care reference: [North Carolina Extension Gardener Plant Toolbox](https://plants.ces.ncsu.edu/plants/epipremnum-aureum/)

## Beanji-specific values

Values such as `wateringNeed`, `wateringIntervalDays`, `lightRequirements`, and `careDifficulty` are simplified product defaults derived from broad horticultural guidance. They are not copied database fields or exact instructions from the referenced sources.

Actual plant needs vary depending on factors such as pot size, substrate, temperature, season, humidity, and available light. Users should treat Beanji's schedules as adjustable reminders.

## Images

The bundled catalog currently contains no third-party plant images. Future local image assets will be created or selected separately and must have documented usage rights before publication.

## Remote data

Remote catalog enrichment is not part of the current default app flow. No responses from the Perenual API are included in the bundled catalog.
