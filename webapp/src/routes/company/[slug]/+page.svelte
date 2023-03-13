<script lang="ts">
    import type { PageData } from './$types';
    import CardListFeedback from '$lib/components/CardListFeedback.svelte';
    import { onMount } from "svelte";
    import FlameIcon from '$lib/icons/flame.svg?component';
    import ClockIcon from '$lib/icons/clock.svg?component';
    import MessageSquareIcon from '$lib/icons/messageSquare.svg?component';

    export let data: PageData;

    let companySlug: string = data.companySlug;

    // first loaded by server load function instead of onMount because we do not
    // want to show an empty list to the user initally
    let feedbacksMostVoted = data.feedbacksMostVoted?.data ?? [];
    let feedbacksMostCommented = data.feedbacksMostCommented?.data ?? [];
    let feedbacksNewest = data.feedbacksNewest?.data ?? [];

    // for determining if we need to display "Load More" button based on the initial load 
    let total_count = data.feedbacksMostVoted?.meta?.filter_count || 0;

    let pageSize: number = data.feedbackLimit;
    let pageNumber: number = 1; 
    let isLoading: boolean = true;

    // show loadMore button when total loaded so far is less than available
    $: hasMore = feedbacksMostVoted.length < total_count; 

    onMount(()=> {
        isLoading = false;
	})

    const fetchFeedbacks = async (pageParam = 1) => {
        const response = await fetch(`/api/feedback?companySlug=${companySlug}&page=${pageParam}&limit=${pageSize}` , {
			            headers: { accept: 'application/json' }
		            });
        
        const result = await response.json();

        if (result.feedbacksMostVoted.data.length > 0) {
            feedbacksMostVoted = [...feedbacksMostVoted, ...result.feedbacksMostVoted.data];
            feedbacksMostCommented = [...feedbacksMostCommented, ...result.feedbacksMostCommented.data];
            feedbacksNewest = [...feedbacksNewest, ...result.feedbacksNewest.data];
        }
        
    };

    // on:click load more function
    const handleLoadMore = async () => {
        pageNumber++;

        if (hasMore) {
            isLoading = true;
            await fetchFeedbacks(pageNumber);
            isLoading = false;
        }
	}

</script>

<!-- Grid -->
<div class="mt-9 mb-10 grid sm:grid-cols-2 lg:grid-cols-3 gap-8 items-start">

    <CardListFeedback feedbacks={feedbacksMostVoted}>
        <div slot="listName" class="flex justify-evenly">
            <FlameIcon width=20 />
            Most Popular
            <FlameIcon width=20 />
        </div>

        <div slot="loadMore">
            <button class="disabled:opacity-30 mt-5 inline-flex justify-center items-center gap-2 rounded-md border-blue-600 font-semibold 
                    text-blue-600 hover:shadow-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-all 
                    text-sm py-5 px-14 dark:text-blue-500 dark:border-blue-600 dark:hover:border-blue-700" 
                    on:click={handleLoadMore}
                    disabled={!hasMore} >
                {#if isLoading}
                    Loading ...
                {:else if hasMore}
                    Load More
                {:else}
                    No more feedbacks
                {/if}
            </button>
        </div>
    </CardListFeedback>

    <CardListFeedback feedbacks={feedbacksMostCommented}>
        <div slot="listName" class="flex justify-evenly">
            <MessageSquareIcon width=20 />
            Most discussed 
            <MessageSquareIcon width=20 />
        </div>

        <div slot="loadMore">
            <button class="disabled:opacity-30 mt-5 inline-flex justify-center items-center gap-2 rounded-md border-blue-600 font-semibold 
                    text-blue-600 hover:shadow-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-all 
                    text-sm py-5 px-14 dark:text-blue-500 dark:border-blue-600 dark:hover:border-blue-700" 
                    on:click={handleLoadMore}
                    disabled={!hasMore} >
                {#if isLoading}
                    Loading ...
                {:else if hasMore}
                    Load More
                {:else}
                    No more feedbacks
                {/if}
            </button>
        </div>
    </CardListFeedback>

    <CardListFeedback feedbacks={feedbacksNewest}>
        <div slot="listName" class="flex justify-evenly">
            <ClockIcon width=20 />
            Most Recent
            <ClockIcon width=20 />
        </div>

        <div slot="loadMore" class="flex justify-evenly">
            <button class="disabled:opacity-30 mt-5 inline-flex justify-center items-center gap-2 rounded-md border-blue-600 font-semibold 
                    text-blue-600 hover:shadow-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-all 
                    text-sm py-5 px-14 dark:text-blue-500 dark:border-blue-600 dark:hover:border-blue-700" 
                    on:click={handleLoadMore}
                    disabled={!hasMore} >
                {#if isLoading}
                    Loading ...
                {:else if hasMore}
                    Load More
                {:else}
                    No more feedbacks
                {/if}
            </button>
        </div>
    </CardListFeedback>

</div>
<!-- End Grid -->