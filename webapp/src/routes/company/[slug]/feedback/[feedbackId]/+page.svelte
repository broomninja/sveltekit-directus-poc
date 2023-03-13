<script lang="ts">
    import type { PageData } from './$types';
    import { Toaster } from 'svelte-french-toast';
    import CommentList from '$lib/components/CommentList.svelte';
    import VoteCounter from '$lib/components/VoteCounter.svelte';
    import Voter from '$lib/components/Voter.svelte';
    import ButtonWithTooltip from '$lib/components/ButtonWithTooltip.svelte';
    import ReplyFeedback from '$lib/components/ReplyFeedback.svelte';
    import DisplayName from '$lib/components/DisplayName.svelte';
    import DisplayTime from '$lib/components/DisplayTime.svelte';
    import ButtonNewFeedback from '$lib/components/ButtonNewFeedback.svelte';

    export let data: PageData;

    $: ({ user, feedback, userVote, votes, voteLimit, comments} = data)

</script>

<svelte:head>
  <title>{!feedback ? 'No feedback found' : `Feedback - ${feedback.title.replaceAll('-', ' ')}`}</title> 
</svelte:head>



{#if !feedback}
<h3>No feedback found</h3>
{:else}

<div class="grid md:grid-cols-5 gap-4">
    <!-- 1st Col -->
    <div class="col-span-3 pl-2 pt-0 pb-4 mr-2 ml-0 lg:mt-0 lg:mb-6 lg:mr-2 lg:ml-0">
        <!-- Feedback -->
        <div class="grid md:grid-cols-9 grid-flow-row gap-1 pt-4 pb-4 pl-2 bg-gray-100 rounded">
            <div class="col-span-7 row-span-2 ml-1 mb-2 text-2xl font-bold text-gray-800 lg:leading-tight dark:text-white">
                {feedback.title}
            </div>

            <!-- Vote Counter -->
            <div class="col-span-2 row-span-2 text-right">
                <VoteCounter {user} {feedback} {userVote}/>
            </div>
            <!-- End Vote Counter -->

            <!-- Author -->
            <div class="col-span-9 row-span-2">                         
                <DisplayName user={feedback.author_id} />
            </div>
            <!-- End Author -->

            <div class="col-span-9 mt-5 ml-2 text-gray-800 dark:text-gray-400">
                {@html feedback.content}
            </div>
            <div class="col-span-9 mt-4 ml-1 p-0">
                <DisplayTime prefix={'created'} datetime={feedback.date_created} /> 
            </div>
        </div>
        <!-- End Feedback -->

        <!-- Reply -->
        <div class="mt-4 ml-1">
            <ReplyFeedback {feedback}/>
        </div>
        <!-- End Reply -->

        <div class="mt-2 ml-0">
            <CommentList {comments}/>
        </div>

    </div>


    <!-- 2nd Col -->
    <div class="min-w-[18rem] min-h-[20rem] bg-gray-100 rounded-md pl-5 pt-2 pb-4 mr-2 ml-2 lg:mt-0 lg:mb-6 lg:mr-6 lg:ml-0">

        <div class="mb-5 mt-2 mr-8">
            Voters
        </div>

        {#each votes as vote}
        <Voter {vote} />
        {:else}
        <div>
            No voters found
        </div>
        {/each}

        {#if feedback.voter_count > voteLimit}
        <div>
            Load {feedback.voter_count - voteLimit} more ...
        </div>
        {/if}   
    </div>
    <!-- End Col -->
</div>

{/if}
