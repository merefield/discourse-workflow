import { LinkTo } from "@ember/routing";
import dIcon from "discourse/helpers/d-icon";
import { or } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";

export default <template>
  <LinkTo class="btn btn-primary" @route={{@route}} @model={{@model}}>
    {{dIcon "plus"}}
    {{i18n (or @label "admin.customize.new")}}
  </LinkTo>
</template>
