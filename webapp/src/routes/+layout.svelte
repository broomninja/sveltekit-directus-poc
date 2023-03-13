<script lang="ts">
    import '../app.css';
    import { Toy } from '@leveluptuts/svelte-toy';
    import { dev } from '$app/environment';
    import { writable } from 'svelte/store';

    import { navigating, page } from '$app/stores';
    import { beforeNavigate } from '$app/navigation';

    import AppHeader from '$lib/components/AppHeader.svelte';
    import Loader from '$lib/components/loading/Loader.svelte';
    import { loading } from '$lib/store/loadingStore';

    $: loading.setNavigate(!!$navigating);

    //$: console.log("[layout.svelte] navigating: " + !!$navigating);
    //$: console.log("[layout.svelte] navigating type: " + $navigating?.type);
    
    $: isLoading = $navigating?.to?.url.pathname === $page.url.pathname;

    //$: console.log("[layout.svelte] navigating to url pathname: " + JSON.stringify($navigating, null, 2));
    //$: console.log("[layout.svelte] page url pathname: " + $page?.url?.pathname);

    beforeNavigate(({ from, to, type, willUnload }) => {
        // ***********************************************
        // ***     show Loader for form submission     ***
        // ***********************************************
        // By default navigating store will not be set to true for form submissions.
        // Form submission will cause a reload (ie 'willUnload' == true) and 'type' will have value 'leave'.
        // if user clicks an external link the 'type' will have value 'link' instead
        // ( see https://github.com/sveltejs/kit/pull/6813 )
        if (willUnload && type === 'leave') {
            loading.setNavigate(true);
        }
        //console.log("[layout.svelte] beforeNavigate: to.url = " + JSON.stringify(to?.url, null, 2));
    });

    let debugCSS = writable({ showLayout: false });

</script>

<Loader />

<AppHeader />
<main>
    <slot />
</main>
<footer />

{#if dev && !!$debugCSS}
    <Toy register={[debugCSS]} />

    {#if $debugCSS.showLayout}
    <style>
        * { outline: 2px dotted red }
        * * { outline: 2px dotted green }
        * * * { outline: 2px dotted orange }
        * * * * { outline: 2px dotted blue }
        * * * * * { outline: 1px solid red }
        * * * * * * { outline: 1px solid green }
        * * * * * * * { outline: 1px solid orange }
        * * * * * * * * { outline: 1px solid blue }
    </style>
    {/if}

{/if}