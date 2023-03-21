<script lang="ts">
    import { onMount, tick } from 'svelte';

    let direction = 'left', // right, top, bottom
        alternate = false,
        behavior = 'auto', // always
        animate = false,
        pausing = true,
        duration = 30, // sec
        loop = true, // false || float
        delay = 0, // sec
        parentSize,
        size,
        self;
    
    $: reverse = direction === 'right' || direction === 'bottom';
    $: horizontal = direction === 'left' || direction === 'right';
    $: vertical = ! horizontal;
    $: measure = horizontal ? 'clientWidth' : 'clientHeight';
    $: iterations = (typeof loop === 'number') ? loop : (loop ? 'infinite' : 1);
    $: dir = reverse ? (alternate ? 'alternate-reverse' : 'reverse') : 
                        (alternate ? 'alternate' : 'normal');
    $: ext = (behavior === 'always' && parentSize > size) ? Math.ceil(parentSize / size) : 0;
    $: rags = ext + (animate && loop && ! alternate);

    let innerWidth = 0;

    $: animate = (innerWidth > 640);
    
    export { direction, duration, delay, loop, pausing, alternate, behavior };
</script>

<svelte:window bind:innerWidth/>

<div 
    bind:this={self} class:animate class:horizontal class:vertical class:pausing 
    style="
        animation-duration: {duration}s;
        animation-delay: {delay}s;
        animation-iteration-count: {iterations};
        animation-direction: {dir};
    "
>
{#each Array(1 + rags) as _}
	<slot>Ticker default content</slot>
{/each}
</div>

<style>
    div { transform: translate3d(0, 0, 0); }
    div.horizontal { display: inline-block; white-space: nowrap; }
    div.vertical { display: block; white-space: normal; }
    div.horizontal > :global(*) { display: inline-block!important; }
    div.vertical > :global(*) { display: block!important; }
    div.animate { animation-timing-function: linear; }
    div.pausing:hover { animation-play-state: paused; }
    div.animate.horizontal { animation-name: horizontal; }
    div.animate.vertical { animation-name: vertical; }

    @keyframes horizontal {
        0%   { transform: translateX(0%); }
        100% { transform: translateX(-50%); }
    }
    @keyframes vertical {
        0%   { transform: translateY(0%); }
        100% { transform: translateY(-50%); }
    }		
</style>