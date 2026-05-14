import { LinkTo } from "@ember/routing";
import dIcon from "discourse/helpers/d-icon";
import { or } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";

export default <template>
  <LinkTo class="btn btn-flat back-button" @route={{@route}} @model={{@model}}>
    {{dIcon "chevron-left"}}
    {{i18n (or @label "back_button")}}
  </LinkTo>
</template>
