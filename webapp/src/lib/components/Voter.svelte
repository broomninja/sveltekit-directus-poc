<script lang="ts">
    import Time from "svelte-time";
    import DisplayName from '$lib/components/DisplayName.svelte';
    import DisplayTime from '$lib/components/DisplayTime.svelte';

    export let vote;
</script>

<div>
    <DisplayName user={vote.voted_by} />
    <div class="ml-9 mt-0 mb-1">
        <DisplayTime prefix={'voted'} datetime={vote.date_created} /> 
    </div>
</div>