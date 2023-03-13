<script lang="ts">
    import CardFeedbackSmall from '$lib/components/CardFeedbackSmall.svelte';
    import { page } from '$app/stores';

    let company = $page.data.company;

    export let feedbacks;

</script>

<!-- Card List -->
<div class="flex flex-col border-2 border-gray-300 text-center rounded-xl p-6 dark:border-gray-700">
    <h4 class="mb-4 font-medium font-semibold text-lg text-gray-800 dark:text-gray-200">
        <slot name="listName" />
    </h4>

    {#each feedbacks as feedback}
        <div class="mx-4 my-2">
            <CardFeedbackSmall companySlug={company.slug} {feedback} />
        </div>
    {/each}

    <slot name="loadMore" />

</div>
<!-- End Card List -->
