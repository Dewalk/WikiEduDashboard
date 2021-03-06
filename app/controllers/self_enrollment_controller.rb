# frozen_string_literal: true
require "#{Rails.root}/lib/wiki_course_edits"
require "#{Rails.root}/lib/wiki_preferences_manager"

#= Controller for students enrolling in courses
class SelfEnrollmentController < ApplicationController
  respond_to :html, :json

  def enroll_self
    # Catch HEAD requests
    respond_to_non_get_request { return }

    set_course
    # Don't allow users to self-enroll if the course has already ended.
    redirect_if_course_ended { return }

    # Redirect to sign in (with callback leading back to this method)
    redirect_if_user_logged_out { return }

    redirect_if_passcode_invalid { return }

    # Creates the CoursesUsers record
    add_student_to_course

    # Make sure the user isn't already enrolled.
    redirect_if_enrollment_failed { return }

    # Set email and VE preferences
    set_mediawiki_preferences if Features.wiki_ed?
    # Automatic edits for newly enrolled user
    make_enrollment_edits

    redirect_to course_slug_path(@course.slug, enrolled: true)
  end

  private

  def respond_to_non_get_request
    return if request.get?
    render json: { status: 200 }
    yield
  end

  def set_course
    @course = Course.find_by_slug(params[:course_id])
    # Check if the course exists
    raise ActionController::RoutingError, 'Course not found' if @course.nil?
  end

  def redirect_if_course_ended
    return unless course_ended?
    flash[:notice] = 'You cannot join this course. It has already ended.'
    redirect_to course_slug_path(@course.slug)
    yield
  end

  def course_ended?
    @course.end < Time.zone.now
  end

  def redirect_if_user_logged_out
    return unless current_user.nil?
    auth_path = user_mediawiki_omniauth_authorize_path
    path = "#{auth_path}?origin=#{request.original_url}"
    redirect_to path
    yield
  end

  def redirect_if_enrollment_failed
    return unless @result[:failure]
    redirect_to course_slug_path(@course.slug, enrolled: false)
    yield
  end

  def redirect_if_passcode_invalid
    return if passcode_valid?
    redirect_to '/errors/incorrect_passcode'
    yield
  end

  def passcode_valid?
    !@course.passcode.nil? && params[:passcode] == @course.passcode
  end

  def add_student_to_course
    @result = JoinCourse.new(course: @course,
                             user: current_user,
                             role: CoursesUsers::Roles::STUDENT_ROLE).result
  end

  def set_mediawiki_preferences
    preferences_manager = WikiPreferencesManager.new(user: current_user)
    preferences_manager.enable_visual_editor
  end

  def make_enrollment_edits
    # Posts templates to userpage and sandbox
    WikiCourseEdits.new(action: :enroll_in_course,
                        course: @course,
                        current_user: current_user)
    # Adds user to course page by updating course page with latest course info
    WikiCourseEdits.new(action: :update_course,
                        course: @course,
                        current_user: current_user)
  end
end
