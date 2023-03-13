<script lang="ts">
    import type { LayoutData } from './$types';
    import { page } from '$app/stores';
    import { Toaster } from 'svelte-french-toast';
    import ButtonNewFeedback from '$lib/components/ButtonNewFeedback.svelte';

    export let data: LayoutData;

    $: ({ company } = data);

    let isUserLoggedIn = !!$page.data.user;

</script>

<Toaster />

<div class="w-full px-4 sm:px-6 md:px-8">
    <div class="max-w-none py-0 ml-3 mr-16 sm:ml-5 sm:mr-5 md:ml-10 md:mr-15 xl:ml-24 xl:mr-24">

        <!-- Content -->
        <div class="mt-9">

            {#if !company}
            <h3>No company found</h3>
            {:else}
            
            <!-- Title -->
            <div class="mb-7 flex items-center font-normal text-xl">
                <div class="">
                    <a href="/company/{company.slug}">
                        <span class="whitespace-nowrap rounded border border-1 border-gray-400 px-5 py-3">
                            Feedback - {company.name}
                        </span>
                    </a>
                </div>
                <ButtonNewFeedback {isUserLoggedIn} companySlug={company.slug}/>
            </div>
            <!-- End Title -->

            <slot />
            
            {/if}
        </div>
        <!-- End Content -->

    </div>
</div>
