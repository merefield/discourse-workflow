import { LinkTo } from "@ember/routing";
import { or } from "truth-helpers";
import dIcon from "discourse-common/helpers/d-icon";
import { i18n } from "discourse-i18n";

<template>
  {{log @model}}
  <LinkTo class="btn btn-primary"
    @route={{@route}}
    @model={{@model}}
    {{!-- @models={{@models}} --}}
  >

{{!-- //      @model={{@model}} --}}
    {{dIcon "plus"}}
    {{i18n (or @label "admin.customize.new")}}
  </LinkTo>
</template>
