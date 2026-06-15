---
name: frontend-design
description: Create distinctive, production-grade frontend interfaces with high design quality. Use this skill when the user asks to build web components, pages, artifacts, posters, or applications (examples include websites, landing pages, dashboards, React components, HTML/CSS layouts, or when styling/beautifying any web UI). Generates creative, polished code and UI design that avoids generic AI aesthetics.
license: Complete terms in LICENSE.txt
---

This skill guides creation of distinctive, production-grade frontend interfaces that avoid generic "AI slop" aesthetics. Implement real working code with exceptional attention to aesthetic details and creative choices.

The user provides frontend requirements: a component, page, application, or interface to build. They may include context about the purpose, audience, or technical constraints.

## Design Thinking

Before coding, understand the context and commit to a BOLD aesthetic direction:
- **Purpose**: What problem does this interface solve? Who uses it?
- **Tone**: Pick an extreme: brutally minimal, maximalist chaos, retro-futuristic, organic/natural, luxury/refined, playful/toy-like, editorial/magazine, brutalist/raw, art deco/geometric, soft/pastel, industrial/utilitarian, etc. There are so many flavors to choose from. Use these for inspiration but design one that is true to the aesthetic direction.
- **Constraints**: Technical requirements (framework, performance, accessibility).
- **Differentiation**: What makes this UNFORGETTABLE? What's the one thing someone will remember?

**CRITICAL**: Choose a clear conceptual direction and execute it with precision. Bold maximalism and refined minimalism both work - the key is intentionality, not intensity.

Then implement working code (HTML/CSS/JS, React, Vue, etc.) that is:
- Production-grade and functional
- Visually striking and memorable
- Cohesive with a clear aesthetic point-of-view
- Meticulously refined in every detail

## Frontend Aesthetics Guidelines

Focus on:
- **Typography**: Choose fonts that are beautiful, unique, and interesting. Avoid generic fonts like Arial and Inter; opt instead for distinctive choices that elevate the frontend's aesthetics; unexpected, characterful font choices. Pair a distinctive display font with a refined body font.
- **Color & Theme**: Commit to a cohesive aesthetic. Use CSS variables for consistency. Dominant colors with sharp accents outperform timid, evenly-distributed palettes.
- **Motion**: Use animations for effects and micro-interactions. Prioritize CSS-only solutions for HTML. Use Motion library for React when available. Focus on high-impact moments: one well-orchestrated page load with staggered reveals (animation-delay) creates more delight than scattered micro-interactions. Use scroll-triggering and hover states that surprise.
- **Spatial Composition**: Unexpected layouts. Asymmetry. Overlap. Diagonal flow. Grid-breaking elements. Generous negative space OR controlled density.
- **Backgrounds & Visual Details**: Create atmosphere and depth rather than defaulting to solid colors. Add contextual effects and textures that match the overall aesthetic. Apply creative forms like gradient meshes, noise textures, geometric patterns, layered transparencies, dramatic shadows, decorative borders, custom cursors, and grain overlays.

NEVER use generic AI-generated aesthetics like overused font families (Inter, Roboto, Arial, system fonts), cliched color schemes (particularly purple gradients on white backgrounds), predictable layouts and component patterns, and cookie-cutter design that lacks context-specific character.

Interpret creatively and make unexpected choices that feel genuinely designed for the context. No design should be the same. Vary between light and dark themes, different fonts, different aesthetics. NEVER converge on common choices (Space Grotesk, for example) across generations.

**IMPORTANT**: Match implementation complexity to the aesthetic vision. Maximalist designs need elaborate code with extensive animations and effects. Minimalist or refined designs need restraint, precision, and careful attention to spacing, typography, and subtle details. Elegance comes from executing the vision well.

Remember: Claude is capable of extraordinary creative work. Don't hold back, show what can truly be created when thinking outside the box and committing fully to a distinctive vision.

## Ground It In The Subject

If the brief does not pin down what the product or subject is, pin it yourself before designing: name one concrete subject, its audience, and the page's single job, and state your choice. If there is context in the request, prior work, or user preferences, use it. Distinctive frontend choices come from the subject's own world, materials, instruments, artifacts, and language.

## Design Principles

For web designs, the hero should make a clear point. Open with the most characteristic thing in the subject's world, in whatever form makes sense for it: a headline, an image, an animation, a live demo, or an interactive moment. Avoid defaulting to generic "headline + stat cards + gradient accent" structures unless the brief actually wants that.

Typography should carry personality. Pair display and body faces deliberately, define a clear type scale, and make the type treatment part of the design rather than a neutral wrapper around the content.

Structure should encode meaning. Numbering, dividers, labels, eyebrows, and section markers should reflect real information, not just decorate the page. If the content is not sequential, do not imply sequence with `01 / 02 / 03`.

Leverage motion deliberately. Use it when it supports the subject and the chosen direction: page-load choreography, scroll reveals, hover feedback, or ambient atmosphere. One orchestrated moment is usually stronger than scattered animation.

## Process

Work in two passes.

First, build a compact design plan from the brief:
- Color: define 4-6 named hex values
- Type: choose faces for display, body, and utility roles if needed
- Layout: describe the structure in one-sentence prose or quick wireframe thinking
- Signature: define the one memorable element that makes the page specific to this brief

Then critique that plan before coding. If any part reads like the same answer you would give for many similar prompts, revise it and make the choice more specific. Only then write the code, following the revised plan rather than improvising generic defaults.

When implementing, watch CSS specificity carefully. Avoid generating selectors that unintentionally override each other, especially around shared section classes, CTAs, and spacing rules.

## Restraint And Self-Critique

Spend boldness in one place. Let the signature element carry the biggest risk, and keep the rest of the interface disciplined. Remove decoration that does not serve the brief.

Build to a quality floor without announcing it: responsive layout, visible keyboard focus, and reduced-motion support where motion is meaningful. Critique your own output as you go, and if your environment allows it, use screenshots to inspect what the page actually looks like rather than trusting the code alone.

## More On Writing In Design

Words are design material. Use them to make the interface easier to understand and use, not to decorate empty space.

Write from the user's side of the screen. Name things by what people control and recognize, not by internal implementation details. Prefer plain, specific labels over clever phrasing.

Use active voice by default. A control should say what happens when it is used, and terminology should stay consistent through the flow. Error states and empty states should give direction rather than mood.

Keep the register conversational and tuned to the product, with sentence case, minimal filler, and one clear job per text element.
