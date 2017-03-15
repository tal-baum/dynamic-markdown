# Dynamic Markdown
Extension to Markdown for creating interactive documents

[Live demo](https://tal-baum.github.io/dynamic-markdown/index.html)

## What is it?
Embedding models and data into documents allows for much more exploration and understanding than is possible with static text and images, but authoring these documents can be time-consuming and require knowledge of HTML, CSS, and JavaScript. Dynamic Markdown is a proposed solution to enable fast and straightforward authoring of interactive documents.

Dynamic Markdown is a work in progress; additional elements and D3 templates for declaratively adding charts coming soon.

## Using Dynamic Markdown
Dynamic Markdown takes as input a plaintext `.md` document and converts it in-browser to [Tangle](http://worrydream.com/Tangle/) code using a Coffeescript plug-in.

The new dynamic content syntax follows this convention:  

    [text content]{variable_name: configuration}

For example:  

    [500 miles]{walk_distance: 100..1000 by 10}

creates an adjustable number initialized at 500 with a range of 100 to 1,000 in increments of 10. Subsequent code can be written using [Coffeescript](http://coffeescript.org/), e.g.

    And I would walk [500]{second_walk} more.
    @second_walk = @walk_distance * 3

## Acknowledgements
To create Dynamic Markdown I revived and combined two GitHub projects that had laid dormant for four years, bringing what I think is the very elegant syntax in Alec Perkins's [ActiveMarkdown](https://github.com/alecperkins/active-markdown) to the lean Coffeescript codebase of @jotux's [Fangle](https://github.com/jotux/fangle).