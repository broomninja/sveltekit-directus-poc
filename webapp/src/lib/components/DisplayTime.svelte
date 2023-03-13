<script lang="ts">
    import Time from "svelte-time";

    export let prefix;
    export let datetime;
</script>

<span class="text-xs text-gray-500 dark:text-gray-400">
    {prefix} <Time relative timestamp="{datetime}" />
</span>

