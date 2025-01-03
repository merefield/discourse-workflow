import { LinkTo } from "@ember/routing";
import { or } from "truth-helpers";
import dIcon from "discourse-common/helpers/d-icon";
import { i18n } from "discourse-i18n";

<template>
  <LinkTo class="btn btn-primary"
    @route={{@route}}
    @models={{@models}}
  >
    {{dIcon "plus"}}
    {{i18n (or @label "admin.customize.new")}}
  </LinkTo>
</template>
